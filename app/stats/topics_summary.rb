class TopicsSummary
  include TopicsQueries, SharedStatsMethods

  attr_reader :stats

  def initialize(user, play_types)
    data = ActiveRecord::Base.connection
                             .select_all(topics_query(user, play_types))
                             .to_hash

    crunch_numbers(data)
  end

  private

  def crunch_numbers(data)
    @stats = Hash.new { |hash, key| hash[key] = Hash.new(0) }

    data.each do |cat_hash|
      if cat_hash['sixth_type']
        add_sixth_to_stats(cat_hash)
      else
        add_final_to_stats(cat_hash)
      end
    end

    add_calculated_stats
  end

  def add_sixth_to_stats(cat_hash)
    topic_stats = @stats[cat_hash['topic']]
    topic_stats[:sixths_count] += 1

    trv = top_row_value(cat_hash)
    1.upto(5) do |row|
      add_clue_to_stats(topic_stats, cat_hash['result' + row.to_s], trv * row)
    end
  end

  def add_final_to_stats(final_hash)
    topic_stats = @stats[final_hash['topic']]
    topic_stats[:finals_count] += 1

    case final_hash['final_result'].to_i
    when 1 then topic_stats[:finals_wrong] += 1
    when 3 then topic_stats[:finals_right] += 1
    end
  end

  def add_calculated_stats
    @stats.each_value do |topic_hash|
      topic_hash[:efficiency] = quotient(topic_hash[:score],
                                         topic_hash[:possible_score])

      topic_hash[:dds] = topic_hash[:dd_right] + topic_hash[:dd_wrong]
    end
  end

  def top_row_value(sixth_hash)
    if sixth_hash['sixth_type'] == 'RoundOneCategory'
      CURRENT_TOP_ROW_VALUES[0]
    else
      CURRENT_TOP_ROW_VALUES[1]
    end
  end
end
