enum WorkSitePhotoSource {
  camera('Camera'),
  library('Photo library'),
  file('File');

  const WorkSitePhotoSource(this.label);
  final String label;
}

class WorkSitePhoto {
  const WorkSitePhoto({
    required this.id,
    required this.path,
    required this.name,
    required this.source,
    required this.addedOn,
    this.note = '',
  });

  final String id;
  final String path;
  final String name;
  final WorkSitePhotoSource source;
  final DateTime addedOn;
  final String note;

  WorkSitePhoto withNote(String value) => WorkSitePhoto(
    id: id,
    path: path,
    name: name,
    source: source,
    addedOn: addedOn,
    note: value,
  );
}
