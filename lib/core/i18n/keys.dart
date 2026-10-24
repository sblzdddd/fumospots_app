/// Translation key constants shared by the three language maps.
abstract final class S {
  // Common
  static const retry = 'common.retry';
  static const cancel = 'common.cancel';
  static const clear = 'common.clear';
  static const close = 'common.close';
  static const search = 'common.search';
  static const processing = 'common.processing';
  static const saving = 'common.saving';
  static const notProvided = 'common.notProvided';
  static const notSet = 'common.notSet';
  static const unnamedPlace = 'common.unnamedPlace';
  static const loadingApp = 'common.loadingApp';

  // Nav
  static const navPosts = 'nav.posts';
  static const navMap = 'nav.map';
  static const navProfile = 'nav.profile';
  static const navAdd = 'nav.add';

  // Settings
  static const settings = 'settings.title';
  static const settingsAppearance = 'settings.appearance';
  static const settingsLanguage = 'settings.language';
  static const settingsStartPage = 'settings.startPage';
  static const settingsVisual = 'settings.visual';
  static const settingsStorage = 'settings.storage';
  static const themeLight = 'settings.themeLight';
  static const themeDark = 'settings.themeDark';
  static const themeSystem = 'settings.themeSystem';
  static const blurEffects = 'settings.blurEffects';
  static const blurOn = 'settings.blurOn';
  static const blurOff = 'settings.blurOff';
  static const clearImageCache = 'settings.clearImageCache';
  static const clearImageCacheHint = 'settings.clearImageCacheHint';
  static const clearImageCacheConfirm = 'settings.clearImageCacheConfirm';
  static const clearImageCacheConfirmUnknown =
      'settings.clearImageCacheConfirmUnknown';
  static const imageCacheCleared = 'settings.imageCacheCleared';
  static const languageEnglish = 'settings.languageEnglish';
  static const languageChinese = 'settings.languageChinese';
  static const languageJapanese = 'settings.languageJapanese';

  // User
  static const notSignedIn = 'user.notSignedIn';
  static const signedIn = 'user.signedIn';
  static const signIn = 'user.signIn';
  static const signOut = 'user.signOut';
  static const setAuthorId = 'user.setAuthorId';
  static const myPosts = 'user.myPosts';
  static const likesCount = 'user.likesCount';
  static const noPostsYet = 'user.noPostsYet';
  static const statusPending = 'user.statusPending';
  static const statusApproved = 'user.statusApproved';
  static const statusRejected = 'user.statusRejected';
  static const statusEditPending = 'user.statusEditPending';

  // Feed / map
  static const contributors = 'feed.contributors';
  static const statsLoadFailed = 'feed.statsLoadFailed';
  static const noPostsMatchFilter = 'feed.noPostsMatchFilter';
  static const postsLoadFailed = 'feed.postsLoadFailed';
  static const postsLoadMoreFailed = 'feed.postsLoadMoreFailed';
  static const noSpotsToShow = 'map.noSpotsToShow';
  static const filterByCharacter = 'filter.byCharacter';
  static const searchCharacters = 'filter.searchCharacters';
  static const charactersLoadFailed = 'filter.charactersLoadFailed';
  static const noMatchingCharacters = 'filter.noMatchingCharacters';

  // Post detail
  static const authorNote = 'post.authorNote';
  static const characters = 'post.characters';
  static const postUnavailableTitle = 'post.unavailableTitle';
  static const signInToLike = 'post.signInToLike';
  static const likeUpdateFailed = 'post.likeUpdateFailed';
  static const sharePhoto = 'post.sharePhoto';
  static const copyImageLink = 'post.copyImageLink';
  static const shareImageLink = 'post.shareImageLink';
  static const linkCopied = 'post.linkCopied';
  static const shareFailed = 'post.shareFailed';

  // Auth
  static const loginRegister = 'auth.loginRegister';
  static const authorId = 'auth.authorId';
  static const logIn = 'auth.logIn';
  static const register = 'auth.register';
  static const email = 'auth.email';
  static const password = 'auth.password';
  static const emailAddress = 'auth.emailAddress';
  static const emailHint = 'auth.emailHint';
  static const passwordHint = 'auth.passwordHint';
  static const confirmPassword = 'auth.confirmPassword';
  static const confirmPasswordHint = 'auth.confirmPasswordHint';
  static const emailLinkOrCode = 'auth.emailLinkOrCode';
  static const emailLinkOrCodeHint = 'auth.emailLinkOrCodeHint';
  static const pasteEmailLinkOrCode = 'auth.pasteEmailLinkOrCode';
  static const continueAction = 'auth.continue';
  static const sendLoginLink = 'auth.sendLoginLink';
  static const emailLink = 'auth.emailLink';
  static const authorIdHint = 'auth.authorIdHint';
  static const authorIdHelper = 'auth.authorIdHelper';
  static const saveAuthorId = 'auth.saveAuthorId';
  static const chooseEmailMethod = 'auth.chooseEmailMethod';
  static const enterEmail = 'auth.enterEmail';
  static const passwordTooShort = 'auth.passwordTooShort';
  static const passwordsDoNotMatch = 'auth.passwordsDoNotMatch';
  static const authorIdInvalid = 'auth.authorIdInvalid';
  static const emailCodeRequired = 'auth.emailCodeRequired';
  static const profileLoadFailed = 'auth.profileLoadFailed';
  static const githubLogin = 'auth.githubLogin';
  static const githubRegister = 'auth.githubRegister';
  static const githubFailed = 'auth.githubFailed';
  static const googleLogin = 'auth.googleLogin';
  static const googleRegister = 'auth.googleRegister';
  static const googleFailed = 'auth.googleFailed';
  static const microsoftLogin = 'auth.microsoftLogin';
  static const microsoftRegister = 'auth.microsoftRegister';
  static const microsoftFailed = 'auth.microsoftFailed';

  // Upload
  static const newSpot = 'upload.newSpot';
  static const editSpot = 'upload.editSpot';
  static const submitSpot = 'upload.submitSpot';
  static const saveChanges = 'upload.saveChanges';
  static const photos = 'upload.photos';
  static const library = 'upload.library';
  static const camera = 'upload.camera';
  static const readingPhotoDetails = 'upload.readingPhotoDetails';
  static const removePhoto = 'upload.removePhoto';
  static const removePhotoConfirm = 'upload.removePhotoConfirm';
  static const remove = 'upload.remove';
  static const titleRequired = 'upload.titleRequired';
  static const titleHint = 'upload.titleHint';
  static const notes = 'upload.notes';
  static const captured = 'upload.captured';
  static const clearDate = 'upload.clearDate';
  static const chooseCharacters = 'upload.chooseCharacters';
  static const retryCharacters = 'upload.retryCharacters';
  static const location = 'upload.location';
  static const device = 'upload.device';
  static const photoExif = 'upload.photoExif';
  static const placeName = 'upload.placeName';
  static const searchPlace = 'upload.searchPlace';
  static const searchPlaceHint = 'upload.searchPlaceHint';
  static const searchPlaces = 'upload.searchPlaces';
  static const country = 'upload.country';
  static const region = 'upload.region';
  static const city = 'upload.city';
  static const latitude = 'upload.latitude';
  static const longitude = 'upload.longitude';
  static const readingDeviceLocation = 'upload.readingDeviceLocation';
  static const lookingUpPlace = 'upload.lookingUpPlace';
  static const readingPhotoLocation = 'upload.readingPhotoLocation';
  static const converting = 'upload.converting';
  static const uploading = 'upload.uploading';
  static const submitting = 'upload.submitting';
  static const compressFailed = 'upload.compressFailed';
  static const openPhotosFailed = 'upload.openPhotosFailed';
  static const openCameraFailed = 'upload.openCameraFailed';
  static const loadEditFailed = 'upload.loadEditFailed';
  static const addPhotoFirst = 'upload.addPhotoFirst';
  static const noLocalExif = 'upload.noLocalExif';
  static const photoNoLocation = 'upload.photoNoLocation';
  static const readPhotoDetailsFailed = 'upload.readPhotoDetailsFailed';
  static const searchMinChars = 'upload.searchMinChars';
  static const noPlacesFound = 'upload.noPlacesFound';
  static const placeSearchFailed = 'upload.placeSearchFailed';
  static const addAtLeastOnePhoto = 'upload.addAtLeastOnePhoto';
  static const maxPhotos = 'upload.maxPhotos';
  static const titleValidation = 'upload.titleValidation';
  static const bodyValidation = 'upload.bodyValidation';
  static const chooseCharacter = 'upload.chooseCharacter';
  static const setLocation = 'upload.setLocation';
  static const signInToPost = 'upload.signInToPost';
  static const updateFailed = 'upload.updateFailed';
  static const submitFailed = 'upload.submitFailed';
  static const spotSubmitted = 'upload.spotSubmitted';
  static const spotUpdated = 'upload.spotUpdated';
  static const enterLatLng = 'upload.enterLatLng';
  static const latitudeRange = 'upload.latitudeRange';
  static const longitudeRange = 'upload.longitudeRange';
  static const locationServicesOff = 'upload.locationServicesOff';
  static const locationPermission = 'upload.locationPermission';
  static const deviceLocationFailed = 'upload.deviceLocationFailed';
  static const uploadTargetMissing = 'upload.uploadTargetMissing';
  static const postUnavailable = 'upload.postUnavailable';
  static const profilePostsFailed = 'user.profilePostsFailed';
}
