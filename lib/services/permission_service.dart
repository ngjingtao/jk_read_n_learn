import 'package:permission_handler/permission_handler.dart' as permissions;

/// What the operating system currently thinks about microphone access.
enum MicrophoneAccess {
  /// Usable right now.
  granted,

  /// Never asked, or the child dismissed the prompt. Asking again is allowed.
  denied,

  /// The parent said no and the system will not ask again. Only a trip to the
  /// device settings can fix this, so the app must say so plainly instead of
  /// showing a button that silently does nothing.
  permanentlyDenied,

  /// Blocked by device policy (parental controls, MDM). Not fixable by us.
  restricted,
}

/// Reads and requests microphone access.
///
/// An interface so the session controller can be tested without a device.
abstract interface class MicrophonePermissions {
  /// Current status, without prompting.
  Future<MicrophoneAccess> microphoneStatus();

  /// Prompts for access if it has not been granted. Returns the new status.
  Future<MicrophoneAccess> requestMicrophone();

  /// Opens the OS settings page for this app, for the permanently-denied case.
  Future<bool> openSettings();
}

/// Talks to the platform permission APIs.
///
/// Kept separate from speech recognition on purpose. The recogniser *also* asks
/// for the microphone, but it reports denial as a generic "could not
/// initialise", which is indistinguishable from "this device has no dictation at
/// all". Those are two different problems with two different fixes for a parent,
/// so the permission question is asked separately and answered precisely.
class PermissionService implements MicrophonePermissions {
  const PermissionService();

  @override
  Future<MicrophoneAccess> microphoneStatus() async {
    try {
      return _map(await permissions.Permission.microphone.status);
    } catch (_) {
      return MicrophoneAccess.denied;
    }
  }

  @override
  Future<MicrophoneAccess> requestMicrophone() async {
    try {
      return _map(await permissions.Permission.microphone.request());
    } catch (_) {
      return MicrophoneAccess.denied;
    }
  }

  @override
  Future<bool> openSettings() => permissions.openAppSettings();

  MicrophoneAccess _map(permissions.PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return MicrophoneAccess.granted;
    }
    if (status.isPermanentlyDenied) return MicrophoneAccess.permanentlyDenied;
    if (status.isRestricted) return MicrophoneAccess.restricted;
    return MicrophoneAccess.denied;
  }
}
