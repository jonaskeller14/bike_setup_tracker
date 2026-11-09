// Text the flows type into the app, per store locale (-e LOCALE=de-DE, set by
// the run scripts; en-US when a flow runs by hand). Only text typed by the
// flow lives here; the names and notes of the sample's records are translated
// by the dictionaries in assets/data/sample_l10n.
var notes = {
  'en-US': 'Loose over hard. Slowed rebound and firmed up for the long descents.',
  'de-DE': 'Locker auf hartem Boden. Zugstufe verlangsamt und für die langen Abfahrten fester gestellt.',
  'fr-FR': 'Souple sur sol dur. Détente ralentie et plus ferme pour les longues descentes.',
  'it-IT': 'Morbido su terreno duro. Ritorno rallentato e più fermo per le lunghe discese.',
  'es-ES': 'Blando sobre suelo duro. Rebote más lento y más firme para los descensos largos.',
  'pt-BR': 'Macio no chão duro. Retorno mais lento e mais firme para as descidas longas.',
};
var locale = typeof LOCALE === 'undefined' ? 'en-US' : LOCALE;
output.setupNotes = notes[locale] || notes['en-US'];
