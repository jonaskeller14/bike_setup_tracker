// The sample's busiest month (mid-May 2026) sits 35 days before its newest
// date (2026-06-20), which the date shift places on yesterday. Page the month
// view back from today's month to the month of (today - 36 days).
var busiest = new Date(Date.now() - 36 * 24 * 60 * 60 * 1000);
var now = new Date();
output.monthsBack = (now.getFullYear() - busiest.getFullYear()) * 12 + now.getMonth() - busiest.getMonth();
