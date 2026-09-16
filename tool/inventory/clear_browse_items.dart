import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('assets/inventory/browse_batch.sqlite', mode: OpenMode.readWrite);
  try {
    db.execute('BEGIN IMMEDIATE');
    db.execute('DELETE FROM items');
    db.execute('DELETE FROM batch_info');
    db.execute('COMMIT');
    db.execute('VACUUM');
    print('Items: ${db.select('SELECT count(*) AS n FROM items').single['n']}; trades: ${db.select('SELECT count(*) AS n FROM trades').single['n']}');
  } finally { db.close(); }
}
