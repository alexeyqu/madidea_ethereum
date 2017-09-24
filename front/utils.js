function getFrom(url) {
    if (!url) url = window.location.search;
    var regex = new RegExp("[?&]" + "from" + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return results[2];
}