"""Independent PDF reopen/content/geometry checks after Flutter fixture tests."""
import json
from pathlib import Path
import pymupdf

root = Path(__file__).resolve().parents[1] / 'output/pdf/infrastructure'
reports = []
for path in sorted(root.glob('*.pdf')):
    expected = json.loads(path.with_suffix('.json').read_text())
    doc = pymupdf.open(path)
    assert len(doc) == expected['pages'], path
    texts = [page.get_text() for page in doc]
    text = '\n'.join(texts)
    for marker in ['LONG-COMPANY-BEGIN', 'LONG-COMPANY-END', 'CUSTOMER-BEGIN',
                   'CUSTOMER-END', 'NOTES-BEGIN', 'NOTES-END', 'FINAL TOTAL']:
        assert marker in text, (path, 'lost content', marker)
    for row in range(expected['rows']):
        for prefix in ['ROW', 'END']:
            marker = f'{prefix}-{row:03}'
            assert text.count(marker) == 1, (path, marker, text.count(marker))
    for index, page in enumerate(doc):
        assert (page.rect.width > page.rect.height) == expected['landscape']
        assert f'Page {index+1} of {len(doc)}' in texts[index], (path, index)
        assert 'Shared footer verification' in texts[index]
        assert 'Verification document 001' in texts[index]
        if 'ROW-' in texts[index] or 'END-' in texts[index]:
            for header in ['Description', 'Quantity', 'Amount']:
                assert header in texts[index], (path, index, 'missing table header')
        for word in page.get_text('words'):
            box = pymupdf.Rect(word[:4])
            assert page.rect.contains(box), (path, index, 'text outside page', word)
    images = doc[0].get_image_info()
    if path.stem.endswith(('-wide', '-tall', '-transparent', '-jpeg')):
        assert images, (path, 'missing logo')
        logo = images[0]
        box = pymupdf.Rect(logo['bbox'])
        assert box.width <= 160.01 and box.height <= 64.01
        assert abs(box.width / box.height - logo['width'] / logo['height']) < .001
    if path.stem in ['portrait-wide', 'landscape-transparent']:
        for index in [0, 1, len(doc)-1]:
            doc[index].get_pixmap(matrix=pymupdf.Matrix(1.2, 1.2)).save(
                root / f'{path.stem}-page-{index+1}.png')
    reports.append({'file': path.name, 'pages': len(doc), 'checks': 'passed'})
assert len(reports) == 12, 'Run shared_pdf_infrastructure_test.dart first.'
(root / 'verification.json').write_text(json.dumps(reports, indent=2))
print(f'Passed independent reopen, content, pagination, orientation and geometry checks: {len(reports)} PDFs.')
