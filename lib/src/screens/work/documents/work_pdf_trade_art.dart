import 'package:pdf/widgets.dart' as pw;
import '../../../shared/documents/pdf/pdf_document_definition.dart';
import 'document_template.dart';

/// Original vector artwork stays outside the live text area on every page.
/// The scalable frame never fixes the number or height of customer line items.
class WorkPdfTradeArt {
  static pw.Widget? background(PdfLayoutContext c, DocumentLayout layout) {
    if (layout.index < DocumentLayout.masonry.index) return null;
    final w = c.page.format.width, h = c.page.format.height;
    final art = StringBuffer();
    void rect(
      num x,
      num y,
      num width,
      num height,
      String fill, {
      String stroke = 'none',
    }) => art.write(
      '<rect x="$x" y="$y" width="$width" height="$height" fill="$fill" stroke="$stroke"/>',
    );
    void path(
      String d,
      String stroke,
      num width, {
      String fill = 'none',
    }) => art.write(
      '<path d="$d" fill="$fill" stroke="$stroke" stroke-width="$width" stroke-linecap="round"/>',
    );
    if (layout == DocumentLayout.masonry) {
      rect(0, 0, w, h, '#e6dfd3');
      for (var y = 0; y < h; y += 20) {
        for (var x = -30; x < w; x += 62) {
          final offset = (y ~/ 20).isEven ? 0 : 31;
          final color = [
            '#8c4e38',
            '#a7684d',
            '#784c3e',
          ][(x.abs() ~/ 62 + y ~/ 20) % 3];
          rect(x + offset, y + 1, 59, 17, color, stroke: '#b68c70');
        }
      }
      rect(34, 28, w - 68, h - 56, '#f4f1e9', stroke: '#716457');
      for (final y in [12.0, h - 27]) {
        for (var x = 6; x < w; x += 85) {
          rect(x, y, 81, 15, '#b4a18a', stroke: '#6c5c4c');
        }
      }
    } else if (layout == DocumentLayout.plumbing) {
      rect(0, 0, w, h, '#eef3f2');
      for (var y = 0; y < h; y += 48) {
        path('M 0 $y H $w', '#d3ddda', 1);
      }
      for (var x = 0; x < w; x += 48) {
        path('M $x 0 V $h', '#d3ddda', 1);
      }
      rect(42, 38, w - 84, h - 76, '#ffffff');
      final pipe =
          'M 28 ${h - 27} V 45 Q 28 25 48 25 H ${w - 48} Q ${w - 28} 25 ${w - 28} 45 V ${h - 45} Q ${w - 28} ${h - 25} ${w - 48} ${h - 25} H 28';
      path(pipe, '#79482e', 10);
      path(pipe, '#bf8257', 7);
      path(pipe, '#e8b98c', 2);
      for (final y in [90.0, h / 2, h - 90]) {
        rect(21, y, 14, 14, '#bc945d', stroke: '#655445');
        rect(w - 35, y, 14, 14, '#bc945d', stroke: '#655445');
      }
    } else if (layout == DocumentLayout.carpentry) {
      rect(0, 0, w, h, '#8c5835');
      for (var y = 4; y < h; y += 10) {
        path('M 0 $y Q ${w / 3} ${y + 7} ${w / 2} $y T $w $y', '#ad784b', 1);
      }
      rect(38, 38, w - 76, h - 76, '#fffdf7', stroke: '#553923');
      // Carpenter's pencil and a ruler along the lower workbench edge.
      rect(62, h - 26, w - 124, 14, '#d9b573', stroke: '#65451e');
      for (var x = 66; x < w - 62; x += 10) {
        path('M $x ${h - 26} v ${x % 20 == 6 ? 9 : 5}', '#65451e', 1);
      }
      path('M 80 19 H ${w - 120}', '#e1a32d', 7);
      path('M ${w - 120} 19 l 18 0 l -18 -4 Z', '#d8bd91', 1, fill: '#d8bd91');
    } else {
      rect(0, 0, w, h, '#e6eddc');
      rect(37, 36, w - 74, h - 72, '#fffef8');
      for (final x in [18.0, w - 18]) {
        path('M $x 12 V ${h - 12}', '#466640', 2);
        for (var y = 22; y < h - 22; y += 32) {
          path(
            'M $x $y q -20 -20 -12 -24 q 19 2 12 24',
            '#476e39',
            1,
            fill: '#5d8449',
          );
          path(
            'M $x ${y + 12} q 20 -20 12 -24 q -19 2 -12 24',
            '#476e39',
            1,
            fill: '#76994f',
          );
        }
      }
      for (var x = 48; x < w - 40; x += 30) {
        for (final y in [18.0, h - 18]) {
          art.write(
            '<circle cx="$x" cy="$y" r="7" fill="#cb8c43"/><circle cx="$x" cy="$y" r="3" fill="#634824"/>',
          );
        }
      }
    }
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.SvgImage(
        svg:
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $w $h">$art</svg>',
        width: w,
        height: h,
      ),
    );
  }
}
