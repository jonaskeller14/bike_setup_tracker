// Text the flows type into the app, per store locale (-e LOCALE=de-DE, set by
// the run scripts; en-US when a flow runs by hand). Only text typed by the
// flow lives here; names that are record data stay the same in every locale.
var notes = {
  'en-US': 'Loose over hard. Slowed rebound and firmed up for the long descents.',
  'de-DE': 'Locker auf hartem Boden. Zugstufe verlangsamt und für die langen Abfahrten fester gestellt.',
};
var locale = typeof LOCALE === 'undefined' ? 'en-US' : LOCALE;
output.setupNotes = notes[locale] || notes['en-US'];
