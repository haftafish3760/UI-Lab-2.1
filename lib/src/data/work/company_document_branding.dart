import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../storage/local_attachment_store.dart';
import '../../shared/documents/pdf/pdf_branding.dart';
import '../../shared/documents/pdf/pdf_image_resolver.dart';
import 'directory_persistence_session.dart';
import 'models/work_contact_models.dart';

PdfBranding companyDocumentBranding(WorkCompanyProfile profile) => PdfBranding(
  companyName: profile.companyName,
  address: profile.address,
  phone: profile.phone,
  email: profile.email,
  website: profile.website,
  logoReference: profile.logoReference.isEmpty ? null : profile.logoReference,
  licenseNumber: profile.licenseNumber,
  businessIdentifier: profile.businessIdentifier,
  footerText: profile.documentFooter,
  accentColor: profile.documentAccentColor,
);

/// Consumes existing directory authority and attachment manifests. No invoice
/// owns this logo and no extra permission flag or company database is created.
class CompanyDocumentBrandingService {
  const CompanyDocumentBrandingService(this.directory);
  final DirectoryPersistenceSession directory;
  void _authorize({bool editing = false}) {
    directory.requireActiveDraftOwner();
    if (!directory.permissions.canViewCompany ||
        (editing && !directory.permissions.canManageCompany)) {
      throw StateError(
        'Company branding is not available with your current permissions.',
      );
    }
  }

  Future<Uint8List?> readLogo(String reference) async {
    _authorize();
    if (reference.isEmpty) return null;
    final files = await LocalAttachmentStore(directory.database).verifiedFiles(
      organizationId: directory.permissions.organizationId,
      ownerIds: {directory.permissions.organizationId},
      attachmentIds: {reference},
    );
    _authorize();
    if (await files.single.length() > const PdfImageResolver().maxBytes) {
      return null;
    }
    final bytes = await files.single.readAsBytes();
    _authorize();
    return bytes;
  }

  Future<String> retainLogo(File source) async {
    _authorize(editing: true);
    if (await source.length() > const PdfImageResolver().maxBytes) {
      throw const FormatException('Choose a logo smaller than 12 MB.');
    }
    final result = await compute(
      _decodeCompanyLogo,
      await source.readAsBytes(),
    );
    if (result.image == null) {
      throw const FormatException(
        'This photo could not be opened. Try another image or a smaller copy.',
      );
    }
    _authorize(editing: true);
    final temporary = await Directory.systemTemp.createTemp('company-logo-');
    try {
      final normalized = File(path.join(temporary.path, 'logo.png'));
      await normalized.writeAsBytes(result.image!.bytes, flush: true);
      _authorize(editing: true);
      final retained = await LocalAttachmentStore(directory.database).retain(
        source: normalized,
        organizationId: directory.permissions.organizationId,
        ownerId: directory.permissions.organizationId,
      );
      _authorize(editing: true);
      return path.basenameWithoutExtension(retained.path);
    } finally {
      await temporary.delete(recursive: true);
    }
  }
}

PdfImageResult _decodeCompanyLogo(Uint8List bytes) =>
    const PdfImageResolver(allowCommonFormats: true).decode(bytes);
