watchEvents(function(error, event) {
    console.log(event);
    if (event && event.event === 'getNewClaimResult') {
        window.location.href = 'task.html?pending=true&pid=' + event.args.proposalId.c[0];
    }
});

function openCity(evt, cityName) {
    // Declare all variables
    var i, tabcontent, tablinks;

    // Get all elements with class="tabcontent" and hide them
    tabcontent = document.getElementsByClassName("tabcontent");
    for (i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = "none";
    }

    // Get all elements with class="tablinks" and remove the class "active"
    tablinks = document.getElementsByClassName("tablinks");
    for (i = 0; i < tablinks.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(" active", "");
    }

    // Show the current tab, and add an "active" class to the button that opened the tab
    console.log(cityName);
    document.getElementById(cityName + '-tab').style.display = "block";
    document.getElementById(cityName).className += " active";
}

openCity(null, getFrom());

