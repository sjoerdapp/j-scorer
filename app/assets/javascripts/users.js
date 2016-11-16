$( ".users-show, .users-sample" ).ready( function() {

  // Returns an array of play type abbreviations corresponding
  // to the checked boxes on the play types tab, or ['none']
  // if no boxes are checked.
  function getCheckedBoxes() {
    var types = $( "#typeTable :checked" ).map( function() {
      return this.id.slice(0, -4);
    }).get();

    if (types.length === 0) { return ['none']; }
    return types;
  }

  $( "#stats-area" ).tabs({
    // Ajax request stuff, mostly pulled from jQuery UI's docs.
    beforeLoad: function( event, ui ) {

      // There's no need to do a fresh Ajax request each time the tab
      // is clicked. If the tab has been loaded already (or is currently
      // loading), skip the request and display the pre-existing data
      // (or continue with the current request).
      if ( ui.tab.data( "loaded" ) || ui.tab.data( "loading" ) ) {
        event.preventDefault();
        return;
      }

      ui.tab.data( "loading", true );
      ui.panel.html( "Retrieving data - one moment please..." );

      ui.jqXHR.success( function() {
        ui.tab.data( "loading", false );
        ui.tab.data( "loaded", true );
      });

      ui.jqXHR.fail( function() {
        ui.tab.data( "loading", false );
        ui.panel.html( "Couldn't load this tab. Please try again later." );
      });
    }
  });

  // Make "Games" table sortable. Initialize default sort to
  // [ leftmost column, descending ]. Prevent meaningless attempts
  // to sort by "Actions" column (currently in position 7).
  $( "#gameTable" ).tablesorter({
    sortList: [[0,1]],
    headers: {
      7: { sorter: false }
    }
  });

  $( "#gameTable" ).stickyTableHeaders({
    scrollableArea: $( '#stats-area' )
  });

  // Similar for "Play types" table. Initialize default sort to
  // [ Games played, descending ]. Prevent meaningless attempts
  // to sort by checkbox column (currently in position 0).
  $( "#typeTable" ).tablesorter({
    sortList: [[2,1]],
    headers: {
      0: { sorter: false }
    }
  });

  $( "#typeTable" ).stickyTableHeaders({
    scrollableArea: $( '#stats-area' )
  });

  var $untracked = $( "tr.untracked" );
  $untracked.hide();

  $( "#show-all-games" ).on( "click", function() {
    $untracked.show();
    $( "#some-hidden" ).hide();
    $( "#all-shown" ).show();
  });

  $( "#hide-untracked-games" ).on( "click", function() {
    $untracked.hide();
    $( "#all-shown" ).hide();
    $( "#some-hidden" ).show();
  });

  $( "#update-displayed-types" ).on( "click", function() {
    if ( !$( this ).hasClass( "disabled" ) ) {
      $( this ).addClass( "disabled" ).html( 'Updating...' );
      $.ajax({
        url: '/types',
        method: 'PATCH',
        data: { play_types: getCheckedBoxes() },
        dataType: 'json',
        success: function() { window.location.replace( '/stats' ); },
        error: function() {
          alert('Oops. Something went wrong.');
          $( "#update-displayed-types" ).removeClass( "disabled" )
                                        .html( 'Update stats' );
        }
      });
    }
  });

  $( "#update-sample-types" ).on( "click", function() {
    if ( !$( this ).hasClass( "disabled" ) ) {
      $( this ).addClass( "disabled" ).html( 'Updating...' );
      var url = "/sample?types=" + getCheckedBoxes().join();
      window.location.replace( url );
    }
  });

  // Set the topics tab (currently in position 2) to load in the background
  // as soon as everything else is done.
  $( "#stats-area" ).tabs( "load", 2 );
});
