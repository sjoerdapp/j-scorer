class TopicsSummary
  include SharedStatsMethods

  attr_reader :stats

  def initialize(user, play_types)
    @stats = ActiveRecord::Base.connection
                               .select_all(topics_query(user, play_types))
                               .to_hash
  end

  private

  # rubocop:disable MethodLength
  def topics_query(user, play_types)
    validate_query_inputs(user, play_types)
    play_types_list = format_play_types_for_sql(play_types)
    "
    SELECT
      q.topic_name,
      COUNT(*) FILTER (WHERE q.sixth_type IS NOT NULL) AS sixths_count,
      SUM(q.right) AS right,
      SUM(q.wrong) AS wrong,
      SUM(q.pass) AS pass,
      SUM(q.score) AS score,
      SUM(q.possible_score) AS possible_score,
      (
        CASE
          WHEN SUM(q.possible_score) > 0
            THEN (1.0 * SUM(q.score) / SUM(q.possible_score))
        END
      ) AS efficiency,
      SUM(q.dd_right) + SUM(q.dd_wrong) AS dds,
      SUM(q.dd_right) AS dd_right,
      SUM(q.dd_wrong) AS dd_wrong,
      SUM(q.finals_right) + SUM(q.finals_wrong) AS finals_count,
      SUM(q.finals_right) AS finals_right,
      SUM(q.finals_wrong) AS finals_wrong
    FROM (
      SELECT
        i.topic_name,
        i.sixth_type,
        #{count_results('i', 3)} AS right,
        #{count_results('i', 1)} AS wrong,
        #{count_results('i', 2)} AS pass,
        (
          (#{count_results('i', [3, 7], true)}) -
          (#{count_results('i', 1, true)})
        ) * i.top_row_value AS score,
        (
          #{count_results('i', [1, 2, 3, 5, 6, 7], true)}
        ) * i.top_row_value AS possible_score,
        #{count_results('i', 7)} AS dd_right,
        #{count_results('i', [5, 6])} AS dd_wrong,
        CASE WHEN i.final_result = 3 THEN 1 ELSE 0 END AS finals_right,
        CASE WHEN i.final_result = 1 THEN 1 ELSE 0 END AS finals_wrong
      FROM (
        SELECT
          t.name AS topic_name,
          s.result1,
          s.result2,
          s.result3,
          s.result4,
          s.result5,
          s.type AS sixth_type,
          (
            CASE s.type
              WHEN 'RoundOneCategory' THEN #{CURRENT_TOP_ROW_VALUES[0]}
              WHEN 'RoundTwoCategory' THEN #{CURRENT_TOP_ROW_VALUES[1]}
            END
          ) AS top_row_value,
          f.result AS final_result
        FROM
          topics t
          INNER JOIN category_topics c
            ON t.id = c.topic_id
          LEFT JOIN sixths s
            ON c.category_id = s.id AND c.category_type = 'Sixth'
          LEFT JOIN finals f
            ON c.category_id = f.id AND c.category_type = 'Final'
          LEFT JOIN games gOne
            ON s.game_id = gOne.id
          LEFT JOIN games gTwo
            ON f.game_id = gTwo.id
        WHERE
          t.user_id = #{user.id}
          AND COALESCE(gOne.play_type, gTwo.play_type) IN (#{play_types_list})
      ) i
    ) q
    GROUP BY topic_name
    ORDER BY topic_name
    "
  end
  # rubocop:enable MethodLength

  # rubocop:disable IdenticalConditionalBranches
  def count_results(table, value, weight = false)
    cond = value.is_a?(Array) ? "IN (#{value.join(', ')})" : "= #{value}"
    "
    (CASE WHEN #{table}.result1 #{cond} THEN #{weight ? 1 : 1} ELSE 0 END) +
    (CASE WHEN #{table}.result2 #{cond} THEN #{weight ? 2 : 1} ELSE 0 END) +
    (CASE WHEN #{table}.result3 #{cond} THEN #{weight ? 3 : 1} ELSE 0 END) +
    (CASE WHEN #{table}.result4 #{cond} THEN #{weight ? 4 : 1} ELSE 0 END) +
    (CASE WHEN #{table}.result5 #{cond} THEN #{weight ? 5 : 1} ELSE 0 END)
    "
  end
  # rubocop:enable IdenticalConditionalBranches
end
