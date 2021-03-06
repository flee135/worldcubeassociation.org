$(function() {
  if(document.body.dataset.railsControllerName !== "registrations") {
    return;
  }

  var $registrationsTable = $('table.registrations-table');
  if($registrationsTable.length > 0) {
    var showHideActions = function(e) {
      var $selectedRows = $registrationsTable.find("tr.selected-row");
      $('.selected-registrations-actions').toggle($selectedRows.length > 0);

      var $selectedApprovedRows = $selectedRows.filter(".registration-accepted");
      $('.selected-approved-registrations-actions').toggle($selectedApprovedRows.length > 0);

      var $selectedPendingRows = $selectedRows.filter(".registration-pending");
      $('.selected-pending-registrations-actions').toggle($selectedPendingRows.length > 0);

      var emails = $selectedRows.find("a[href^=mailto]").map(function() { return this.href.match(/^mailto:(.*)/)[1]; }).toArray();
      document.getElementById("email-selected").href = "mailto:" + emails.join(",");
    };
    $registrationsTable.on("change", ".select-row-checkbox", function() {
      // Wait for selectable-rows code to run.
      setTimeout(showHideActions, 0);
    });
    $registrationsTable.on("select-all-none-click", function() {
      // Wait for selectable-rows code to run.
      setTimeout(showHideActions, 0);
    });
    showHideActions();

    $('button[value=delete-selected]').on("click", function(e) {
      if(!confirm("Are you sure you want to delete the selected registrations?")) {
        e.preventDefault();
      }
    });
  }
});
