// The calendar showcase day (18 May 2026 in the sample: a setup, a ride, an
// installation and a task) sits 33 days before the sample's newest date
// (2026-06-20), which the date shift places on yesterday. Outputs how many
// months the month view pages back to reach it, and its cell's label.
var day = new Date(Date.now() - 34 * 24 * 60 * 60 * 1000);
var now = new Date();
var weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
var months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
output.monthsBack = (now.getFullYear() - day.getFullYear()) * 12 + now.getMonth() - day.getMonth();
output.dayLabel = weekdays[day.getDay()] + ', ' + ('0' + day.getDate()).slice(-2) + ' ' + months[day.getMonth()] + ' ' + day.getFullYear();
