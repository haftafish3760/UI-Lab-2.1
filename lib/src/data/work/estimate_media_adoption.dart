import 'work_photo_media_adoption.dart';

/// Compatibility facade for the existing estimate photo workflow.
class EstimateMediaAdoption extends WorkPhotoMediaAdoption {
  const EstimateMediaAdoption(super.repository, super.permissions);
  static const draftDomain = 'work/estimate-editor';
}
