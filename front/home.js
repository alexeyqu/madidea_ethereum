watchEvents(function(error, event) {
    console.log(event);
    if (event && event.event === 'getNewClaimResult') {
        if (event.args.success) {
            window.location.href = 'task.html?pending=true&from=judge&pid=' + event.args.clainId.c[0];
        } else {
            document.getElementById('judge-text').innerHTML = 'There is no appropriate claim for you';
        }
    }
});

function openCity(evt, cityName) {
    if (!cityName) {
        return;
    }
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
