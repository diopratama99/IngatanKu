// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'IngatanKu';

  @override
  String get navHome => 'Beranda';

  @override
  String get navLibrary => 'Pustaka';

  @override
  String get navNotes => 'Catatan';

  @override
  String get navAssistant => 'Asisten';

  @override
  String get navProfile => 'Saya';

  @override
  String get greetingMorning => 'Selamat pagi';

  @override
  String get greetingAfternoon => 'Selamat siang';

  @override
  String get greetingEvening => 'Selamat sore';

  @override
  String get greetingNight => 'Selamat malam';

  @override
  String get dashboardSectionProgress => 'PROGRES';

  @override
  String get dashboardSectionRecentNotes => 'CATATAN KAMU';

  @override
  String get dashboardSectionFeatures => 'FITUR';

  @override
  String get dashboardSectionStats => 'STATISTIK';

  @override
  String get dashboardSectionKnowledgeMap => 'PETA PENGETAHUAN';

  @override
  String get dashboardStatNotes => 'Catatan tersimpan';

  @override
  String get dashboardStatTopTag => 'Tag teratas';

  @override
  String get dashboardKnowledgeMapDetail => 'DETAIL';

  @override
  String get featureWeeklyQuiz => 'Quiz Mingguan';

  @override
  String get featureManageTags => 'Kelola Tag';

  @override
  String get accountSubtitle =>
      'Atur identitasmu di IngatanKu. Perubahan langsung tersinkron dengan dashboard web.';

  @override
  String get accountSectionIdentity => 'IDENTITAS';

  @override
  String get accountSectionSecurity => 'KEAMANAN';

  @override
  String get accountSectionPreferences => 'PREFERENSI';

  @override
  String get accountFieldName => 'Nama';

  @override
  String get accountFieldEmail => 'Email';

  @override
  String get accountFieldEmailCaption =>
      'Hubungi support untuk mengubah email.';

  @override
  String get accountFieldPassword => 'Kata sandi';

  @override
  String get accountFieldLanguage => 'Bahasa';

  @override
  String get localeSystem => 'Ikuti sistem';

  @override
  String get localeSystemCaption =>
      'Pakai bahasa perangkat. Fallback ke English.';

  @override
  String get localeIndonesian => 'Bahasa Indonesia';

  @override
  String get localeEnglish => 'English';

  @override
  String get pickerTitleLanguage => 'BAHASA';

  @override
  String get profilePageEyebrow => 'PROFIL';

  @override
  String get profileFallbackDisplayName => 'Anonim';

  @override
  String get profileSignOutTooltip => 'Keluar';

  @override
  String get profileSignOutDialogTitle => 'Yakin ingin keluar?';

  @override
  String get profileSignOutDialogMessage =>
      'Kamu harus masuk lagi untuk membuka catatanmu.';

  @override
  String get profileSignOutDialogCancel => 'Batal';

  @override
  String get profileSignOutDialogConfirm => 'Keluar';

  @override
  String get profileSectionSettings => 'PENGATURAN';

  @override
  String get profileNavAccount => 'Akun';

  @override
  String get profileNavStorage => 'Penyimpanan offline';

  @override
  String get profileNavAiSearch => 'AI & pencarian';

  @override
  String get profileNavPrivacy => 'Privasi & data';

  @override
  String get profileNavAbout => 'Tentang IngatanKu';

  @override
  String get vaultPageEyebrow => 'PUSTAKA';

  @override
  String get vaultPageTitle => 'Catatanmu.';

  @override
  String get vaultCountEmpty => 'Belum ada catatan';

  @override
  String vaultCountSaved(int count) {
    return '$count catatan tersimpan';
  }

  @override
  String get vaultSearchHint => 'Cari judul, isi, atau #tag…';

  @override
  String get vaultLayoutListTooltip => 'Tampilan detail';

  @override
  String get vaultLayoutGridTooltip => 'Tampilan rak';

  @override
  String get vaultFabNewNote => 'Catatan baru';

  @override
  String get vaultEmptyEyebrow => 'PUSTAKA KOSONG';

  @override
  String get vaultEmptyTitle => 'Mulai\nmenulis';

  @override
  String get vaultEmptyMessage =>
      'Tap \"Catatan baru\" di pojok kanan bawah untuk menyimpan tautan pertamamu, kamu akan dapat 10 XP.';

  @override
  String get vaultNotFoundEyebrow => 'TIDAK DITEMUKAN';

  @override
  String vaultNotFoundTitle(String query) {
    return '\"$query\"\ntidak\nada';
  }

  @override
  String get vaultNotFoundMessage =>
      'Coba kata kunci lain, atau bersihkan pencarian.';

  @override
  String get noteDetailBackTooltip => 'Kembali';

  @override
  String get noteDetailMoreTooltip => 'Aksi lainnya';

  @override
  String get noteDetailUntitled => '(Tanpa judul)';

  @override
  String get noteDetailEmptyMarkdown => '_Belum ada catatan._';

  @override
  String get noteDetailSwipeHint => 'Geser untuk balik halaman';

  @override
  String get chatStarterAsk =>
      'Apa yang bisa aku tanyakan setelah menyimpan beberapa catatan?';

  @override
  String get chatStarterHow => 'Bagaimana kamu menjawab pertanyaanku?';

  @override
  String get chatStarterWhat => 'Apa saja yang enak disimpan di sini?';

  @override
  String chatTagSummary(String tag) {
    return 'Rangkum catatanku tentang #$tag';
  }

  @override
  String chatTagList(String tag) {
    return 'Apa saja yang aku simpan tentang #$tag?';
  }

  @override
  String chatTagPoints(String tag) {
    return 'Beri 3 poin penting dari catatan #$tag';
  }

  @override
  String chatTagTips(String tag) {
    return 'Tampilkan tips praktis tentang #$tag';
  }

  @override
  String chatTagTry(String tag) {
    return 'Apa yang bisa aku coba dari catatan #$tag?';
  }

  @override
  String chatTagPattern(String tag) {
    return 'Apa benang merah catatan #$tag-ku?';
  }

  @override
  String chatCompare(String a, String b) {
    return 'Bandingkan catatanku tentang #$a dan #$b';
  }

  @override
  String chatShared(String a, String b) {
    return 'Apa kesamaan catatan #$a dan #$b?';
  }

  @override
  String chatLink(String a, String b) {
    return 'Apa hubungan antara #$a dan #$b di catatanku?';
  }

  @override
  String chatTitlePoints(String title) {
    return 'Apa poin utama dari \'$title\'?';
  }

  @override
  String chatTitleSummary(String title) {
    return 'Ringkas \'$title\' untukku';
  }

  @override
  String chatTitleTakeaway(String title) {
    return 'Apa yang bisa aku ambil dari \'$title\'?';
  }

  @override
  String chatSource(String source) {
    return 'Apa yang menarik dari catatan $source-ku belakangan?';
  }

  @override
  String get chatSourceArticle => 'artikel';

  @override
  String get chatWeek => 'Apa yang aku simpan minggu ini?';

  @override
  String get chatLatestFive =>
      'Buatkan ringkasan 5 poin dari catatan terbaruku';

  @override
  String get chatTheme =>
      'Tema apa yang paling sering muncul di catatan terakhirku?';

  @override
  String get chatHighlight => 'Apa hal paling menarik yang baru aku simpan?';

  @override
  String get chatNextIdea =>
      'Kasih ide hal baru untuk dicoba atau dipelajari dari catatanku';

  @override
  String get chatDig =>
      'Pertanyaan menarik apa yang bisa aku gali dari catatanku?';

  @override
  String get chatGaps =>
      'Apa yang sepertinya masih kurang aku pahami dari catatanku?';

  @override
  String get playerPlay => 'Putar di sini';

  @override
  String get playerPlaySaved => 'Putar yang tersimpan';

  @override
  String get playerPreparing => 'Menyiapkan…';

  @override
  String get playerRetry => 'Coba lagi';

  @override
  String get playerOpenSource => 'Buka di sumber';

  @override
  String get playerErrRefused =>
      'Servernya menolak. Coba lagi, atau buka di app aslinya.';

  @override
  String get playerErrForbidden =>
      'Akses ditolak (403). Kontennya mungkin privat.';

  @override
  String get playerErrNotFound => 'Kontennya tidak ditemukan (404).';

  @override
  String get playerErrTimeout => 'Kelamaan menunggu. Coba lagi sebentar lagi.';

  @override
  String get playerErrLoad => 'Gagal memuat video. Coba lagi.';

  @override
  String get playerErrOther => 'Tidak bisa diputar di sini. Buka di sumbernya.';

  @override
  String get playerErrWeb => 'Memutar di sini belum bisa di versi web.';

  @override
  String get noteDetailMenuEdit => 'Edit catatan';

  @override
  String get noteDetailMenuOpenSource => 'Buka sumber';

  @override
  String get noteDetailMenuSaveOffline => 'Simpan offline';

  @override
  String get noteDetailMenuDeleteOffline => 'Hapus video offline';

  @override
  String get noteDetailMenuDelete => 'Hapus catatan';

  @override
  String get noteDetailDeleteTitle => 'Hapus catatan ini?';

  @override
  String get noteDetailDeleteMessage =>
      'Catatan akan dihapus dari Pustaka. Tindakan ini tidak bisa dibatalkan.';

  @override
  String get noteDetailDeleteCancel => 'Batal';

  @override
  String get noteDetailDeleteConfirm => 'Hapus';

  @override
  String get noteDetailDeleteLocalTitle => 'Hapus video offline?';

  @override
  String get noteDetailDeleteLocalMessage =>
      'File akan dihapus dari perangkat. Catatan tetap aman dan kamu bisa unduh ulang kapan saja.';

  @override
  String get noteDetailDeleteLocalDone => 'Video offline dihapus';

  @override
  String get noteDetailSaveOfflineEyebrow => 'SIMPAN OFFLINE';

  @override
  String get noteDetailDownloadSavedSnack =>
      'Tersimpan offline · putar dari perangkat';

  @override
  String noteDetailDownloadFailed(String error) {
    return 'Download gagal: $error';
  }

  @override
  String get noteDetailOpenFileFailed =>
      'Tidak ada app yang bisa membuka file ini';

  @override
  String get noteDetailShareFallbackTitle => 'Lihat ini';

  @override
  String get noteDetailLocalDeletedSnack => 'File lokal dihapus';

  @override
  String get noteDetailDownloadIdleTitle => 'Belum tersimpan';

  @override
  String get noteDetailDownloadIdleSubtitle =>
      'Download video/foto ke perangkat';

  @override
  String get noteDetailDownloadAction => 'DOWNLOAD';

  @override
  String noteDetailDownloadingProgress(int percent) {
    return 'Mengunduh… $percent%';
  }

  @override
  String get noteDetailDownloadingPreparing => 'Mempersiapkan…';

  @override
  String get noteDetailDownloadingCancel => 'BATAL';

  @override
  String get noteDetailDownloadSavedTitle => 'Tersimpan offline';

  @override
  String get noteDetailDownloadOpenTooltip => 'Buka';

  @override
  String get noteDetailDownloadShareTooltip => 'Bagikan';

  @override
  String get noteDetailDownloadDeleteTooltip => 'Hapus dari perangkat';

  @override
  String get addNoteEditEyebrow => 'EDIT CATATAN';

  @override
  String get addNoteNewEyebrow => 'CATATAN BARU';

  @override
  String get addNoteEditTitle => 'Edit catatan.';

  @override
  String get addNoteNewTitle => 'Catatan baru.';

  @override
  String get addNoteTogglePreview => 'Pratinjau';

  @override
  String get addNoteToggleEdit => 'Sunting';

  @override
  String get addNoteSectionSource => 'SUMBER';

  @override
  String get addNoteSectionTitle => 'JUDUL (OPSIONAL)';

  @override
  String get addNoteSectionNotes => 'CATATANMU';

  @override
  String get addNoteSectionTags => 'TAG';

  @override
  String get quizToggleTitle => 'Jadi bahan kuis';

  @override
  String get quizToggleOn =>
      'Soal dari catatan ini bisa muncul di kuis harian dan pesta mingguan.';

  @override
  String get quizToggleOff =>
      'Tidak akan jadi soal kuis. Cocok untuk link yang cukup disimpan, seperti judul komik atau buku.';

  @override
  String get formatBold => 'Tebal';

  @override
  String get formatHeading => 'Judul';

  @override
  String get formatBullets => 'Daftar';

  @override
  String get formatNumbers => 'Daftar bernomor';

  @override
  String get addNoteUrlHint => 'https://youtube.com/shorts/…';

  @override
  String get addNoteTitleHint => 'Beri nama yang mudah diingat';

  @override
  String get addNoteNotesHint =>
      'Tulis insight, ringkasan, atau hal yang ingin kamu ingat dari konten ini.';

  @override
  String get addNoteUrlRequired => 'URL wajib diisi';

  @override
  String get addNoteUrlMustStartWithHttp => 'Harus diawali http(s)';

  @override
  String get addNoteNotesMinLength => 'Minimal 10 karakter';

  @override
  String get addNoteAutoFillNeedUrl => 'Isi URL valid dulu';

  @override
  String get addNoteAutoFillTranscribing => 'Transkripsi video…';

  @override
  String get addNoteAutoFillProcessing => 'Memproses…';

  @override
  String addNoteAutoFillContentFound(String contentLabel) {
    return '$contentLabel ditemukan, menyusun catatan…';
  }

  @override
  String addNoteAutoFillError(String error) {
    return 'Auto-fill gagal: $error';
  }

  @override
  String get addNoteAutoFillTooltipProcessing => 'Memproses…';

  @override
  String get addNoteAutoFillTooltipTranscribe =>
      'Auto-fill (transkripsi video)';

  @override
  String get addNoteAutoFillTooltipUrl => 'Auto-fill dari URL';

  @override
  String get addNoteReplaceDialogTitle => 'Ganti catatan saat ini?';

  @override
  String get addNoteReplaceDialogTranscribe =>
      'Auto-fill akan menghapus draft kamu, mentranskripsi audio video, lalu menyusun catatan baru.';

  @override
  String get addNoteReplaceDialogScrape =>
      'Auto-fill akan menghapus draft kamu dan menggantinya dengan catatan baru dari URL.';

  @override
  String get addNoteReplaceDialogCancel => 'Batal';

  @override
  String get addNoteReplaceDialogConfirm => 'Ganti';

  @override
  String get addNotePreviewEmpty => '_Belum ada yang bisa dipratinjau…_';

  @override
  String get addNoteSavedSnack => 'Catatan tersimpan.';

  @override
  String get addNoteUpdatedSnack => 'Perubahan tersimpan';

  @override
  String get addNoteSaveButton => 'Simpan ke Pustaka';

  @override
  String get addNoteUpdateButton => 'Simpan perubahan';

  @override
  String get personalNotesEyebrow => 'CATATAN';

  @override
  String get personalNotesTitle => 'Pikiranmu.';

  @override
  String get personalNotesCountEmpty => 'Belum ada catatan';

  @override
  String personalNotesCount(int count) {
    return '$count catatan';
  }

  @override
  String get personalNotesSearchHint => 'Cari catatan, isi, atau #tag…';

  @override
  String get personalNotesPinnedEyebrow => 'TERSEMAT';

  @override
  String get personalNotesOthersEyebrow => 'LAINNYA';

  @override
  String get personalNotesFabNew => 'Catatan baru';

  @override
  String get personalNotesEmptyEyebrow => 'KOSONG';

  @override
  String get personalNotesEmptyTitle => 'Tulis\npikiranmu';

  @override
  String get personalNotesEmptyMessage =>
      'Tap \"Catatan baru\" untuk mulai. Bisa teks bebas, gambar, dan link.';

  @override
  String get personalNotesNotFoundEyebrow => 'TIDAK DITEMUKAN';

  @override
  String personalNotesNotFoundTitle(String query) {
    return '\"$query\"\ntidak ada';
  }

  @override
  String get personalNotesNotFoundMessage =>
      'Coba kata kunci lain, atau bersihkan pencarian.';

  @override
  String get noteEditorTitleHint => 'Judul';

  @override
  String get noteEditorBodyHint => 'Tulis sesuatu…';

  @override
  String get noteEditorSectionLinks => 'TAUTAN';

  @override
  String get noteEditorSectionTags => 'TAG';

  @override
  String get noteEditorPinTooltip => 'Sematkan';

  @override
  String get noteEditorUnpinTooltip => 'Lepas pin';

  @override
  String get noteEditorColorTooltip => 'Warna';

  @override
  String get noteEditorDeleteTooltip => 'Hapus';

  @override
  String get noteEditorAddImageTooltip => 'Tambah gambar';

  @override
  String get noteEditorAddLinkTooltip => 'Tambah tautan';

  @override
  String get noteEditorRemoveLinkTooltip => 'Hapus tautan';

  @override
  String get noteEditorImageSourceGallery => 'Dari galeri';

  @override
  String get noteEditorImageSourceCamera => 'Ambil foto';

  @override
  String noteEditorImageAddFailed(String error) {
    return 'Gagal menambah gambar: $error';
  }

  @override
  String noteEditorSaveFailed(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get noteEditorDiscardEditTitle => 'Hapus catatan?';

  @override
  String get noteEditorDiscardNewTitle => 'Buang catatan ini?';

  @override
  String get noteEditorDiscardEditMessage =>
      'Catatan dan semua gambarnya akan dihapus permanen.';

  @override
  String get noteEditorDiscardNewMessage =>
      'Draft akan dibuang dan gambar yang sudah dilampirkan ikut hilang.';

  @override
  String get noteEditorDiscardCancel => 'Batal';

  @override
  String get noteEditorDiscardEditConfirm => 'Hapus';

  @override
  String get noteEditorDiscardNewConfirm => 'Buang';

  @override
  String get noteEditorLinkDialogAddTitle => 'Tambah tautan';

  @override
  String get noteEditorLinkDialogEditTitle => 'Edit tautan';

  @override
  String get noteEditorLinkUrlHint => 'https://…';

  @override
  String get noteEditorLinkLabelHint => 'Label (opsional)';

  @override
  String get noteEditorLinkCancel => 'Batal';

  @override
  String get noteEditorLinkSave => 'Simpan';

  @override
  String get noteEditorColorPickerEyebrow => 'WARNA CATATAN';

  @override
  String get noteColorDefault => 'Default';

  @override
  String get noteColorRed => 'Merah';

  @override
  String get noteColorOrange => 'Oranye';

  @override
  String get noteColorYellow => 'Kuning';

  @override
  String get noteColorGreen => 'Hijau';

  @override
  String get noteColorTeal => 'Tosca';

  @override
  String get noteColorBlue => 'Biru';

  @override
  String get noteColorPurple => 'Ungu';

  @override
  String get noteColorPink => 'Pink';

  @override
  String get noteColorBrown => 'Cokelat';

  @override
  String get noteColorGray => 'Abu';

  @override
  String get loginEyebrow => 'INGATANKU';

  @override
  String get loginTitle => 'Selamat\ndatang\nkembali.';

  @override
  String get loginSubtitle => 'Masuk untuk lanjutkan koleksi catatanmu.';

  @override
  String get loginEmailLabel => 'EMAIL';

  @override
  String get loginEmailHint => 'kamu@example.com';

  @override
  String get loginEmailInvalid => 'Email tidak valid';

  @override
  String get loginPasswordLabel => 'KATA SANDI';

  @override
  String get loginPasswordForgot => 'LUPA?';

  @override
  String get loginPasswordHint => 'Minimal 6 karakter';

  @override
  String get loginPasswordTooShort => 'Minimal 6 karakter';

  @override
  String get loginSubmit => 'Masuk';

  @override
  String get loginDivider => 'ATAU';

  @override
  String get loginNoAccount => 'Belum punya akun?  ';

  @override
  String get loginSignUpAction => 'Daftar';

  @override
  String get signupAppBarTitle => 'DAFTAR';

  @override
  String get signupTitle => 'Buat\nakunmu.';

  @override
  String get signupSubtitle =>
      'Peliharaanmu sudah menunggu menetas. Suapi dengan ilmu yang kamu pelajari.';

  @override
  String get signupUsernameLabel => 'NAMA PENGGUNA';

  @override
  String get signupUsernameHint => 'mis. sari.dewi';

  @override
  String get signupUsernameTooShort => 'Minimal 3 karakter';

  @override
  String get signupEmailLabel => 'EMAIL';

  @override
  String get signupEmailHint => 'kamu@example.com';

  @override
  String get signupEmailInvalid => 'Email tidak valid';

  @override
  String get signupPasswordLabel => 'KATA SANDI';

  @override
  String get signupPasswordHint => 'Minimal 6 karakter';

  @override
  String get signupPasswordTooShort => 'Minimal 6 karakter';

  @override
  String get signupSubmit => 'Daftar';

  @override
  String get forgotPasswordAppBarTitle => 'LUPA KATA SANDI';

  @override
  String get forgotPasswordEmailTitle => 'Atur ulang\nkata sandi.';

  @override
  String get forgotPasswordEmailSubtitle =>
      'Masukkan email akunmu, kami akan kirim kode 6 digit untuk verifikasi.';

  @override
  String get forgotPasswordEmailLabel => 'EMAIL';

  @override
  String get forgotPasswordEmailHint => 'kamu@example.com';

  @override
  String get forgotPasswordEmailInvalid => 'Email tidak valid';

  @override
  String get forgotPasswordSendCode => 'Kirim kode reset';

  @override
  String get forgotPasswordOtpTitle => 'Cek\nemailmu.';

  @override
  String get forgotPasswordOtpSubtitleLead => 'Kode 6 digit dikirim ke\n';

  @override
  String get forgotPasswordOtpLabel => 'KODE OTP';

  @override
  String get forgotPasswordOtpVerify => 'Verifikasi';

  @override
  String forgotPasswordOtpResendCooldown(int seconds) {
    return 'Kirim ulang dalam ${seconds}s';
  }

  @override
  String get forgotPasswordOtpResend => 'Kirim ulang kode';

  @override
  String get forgotPasswordNewTitle => 'Buat\nsandi baru.';

  @override
  String get forgotPasswordNewSubtitle =>
      'Pilih kata sandi minimal 6 karakter. Setelah disimpan kamu langsung masuk ke akunmu.';

  @override
  String get forgotPasswordNewLabel => 'KATA SANDI BARU';

  @override
  String get forgotPasswordNewHint => 'Minimal 6 karakter';

  @override
  String get forgotPasswordNewTooShort => 'Minimal 6 karakter';

  @override
  String get forgotPasswordConfirmLabel => 'KONFIRMASI';

  @override
  String get forgotPasswordConfirmHint => 'Ketik ulang kata sandi';

  @override
  String get forgotPasswordConfirmRequired => 'Konfirmasi sandi';

  @override
  String get forgotPasswordConfirmMismatch => 'Sandi tidak sama';

  @override
  String get forgotPasswordSaveAction => 'Simpan & masuk';

  @override
  String get verifyOtpAppBarTitle => 'VERIFIKASI';

  @override
  String get verifyOtpTitle => 'Cek\nemailmu.';

  @override
  String get verifyOtpSubtitleLead => 'Kami mengirim 6 digit kode ke\n';

  @override
  String get verifyOtpLabel => 'KODE OTP';

  @override
  String get verifyOtpVerify => 'Verifikasi';

  @override
  String verifyOtpResendCooldown(int seconds) {
    return 'Kirim ulang dalam ${seconds}s';
  }

  @override
  String get verifyOtpResend => 'Kirim ulang kode';

  @override
  String get verifyOtpResentSnack => 'Kode baru sudah dikirim ke email-mu';

  @override
  String get storageAppBarTitle => 'PENYIMPANAN';

  @override
  String get storageTitle => 'Penyimpanan offline.';

  @override
  String get storageEmptySubtitle =>
      'Belum ada video atau foto yang tersimpan offline.';

  @override
  String storageUsage(int count, String size) {
    return '$count file · $size terpakai';
  }

  @override
  String get storageDeleteOneTitle => 'Hapus file ini?';

  @override
  String get storageDeleteOnePhotoBody =>
      'Foto akan dihapus dari perangkat. Kamu tetap bisa unduh ulang dari catatan.';

  @override
  String get storageDeleteOneVideoBody =>
      'Video akan dihapus dari perangkat. Kamu tetap bisa unduh ulang dari catatan.';

  @override
  String get storageDeleteAllTitle => 'Hapus semua media?';

  @override
  String get storageDeleteAllBody =>
      'Semua video dan foto offline akan dihapus dari perangkat. Catatannya tetap aman dan bisa diunduh ulang kapan saja.';

  @override
  String get storageConfirmCancel => 'Batal';

  @override
  String get storageConfirmDelete => 'Hapus';

  @override
  String get storageDeleteAllAction => 'Hapus semua';

  @override
  String get storageFileDeleted => 'File dihapus';

  @override
  String storageFilesDeleted(int count) {
    return '$count file dihapus';
  }

  @override
  String get storageRowUntitled => '(Tanpa judul)';

  @override
  String get storageRowOrphan => 'Catatan dihapus';

  @override
  String storageRowOrphanLabel(String ext) {
    return 'Orphan · $ext';
  }

  @override
  String get storageRowDeleteTooltip => 'Hapus dari perangkat';

  @override
  String get storageDeleteAllButton => 'Hapus semua media offline';

  @override
  String get reindexAppBarTitle => 'AI & PENCARIAN';

  @override
  String get reindexTitle => 'Indeks AI.';

  @override
  String get reindexSubtitle =>
      'Pakai ini kalau Asisten tidak menemukan catatan lama setelah kamu mengganti model embedding di backend.';

  @override
  String get reindexStatusEyebrow => 'STATUS';

  @override
  String get reindexStatusLoading => 'Memuat…';

  @override
  String reindexStatusReady(int total) {
    return '$total catatan terindeks · semua siap';
  }

  @override
  String reindexStatusMissing(int missing, int total) {
    return '$missing dari $total catatan butuh re-embed';
  }

  @override
  String get reindexRefreshTooltip => 'Refresh';

  @override
  String get reindexStep1Eyebrow => 'LANGKAH 1';

  @override
  String get reindexStep1Title => 'Reset embedding lama';

  @override
  String get reindexStep1Description =>
      'Mengosongkan kolom embedding semua catatanmu. Aman, tidak menghapus catatannya.';

  @override
  String get reindexStep1Action => 'Reset embedding';

  @override
  String get reindexStep1Busy => 'Mereset…';

  @override
  String get reindexStep2Eyebrow => 'LANGKAH 2';

  @override
  String get reindexStep2Title => 'Jalankan re-embed';

  @override
  String get reindexStep2Description =>
      'Mengisi ulang embedding semua catatan yang kosong dengan model AI yang sekarang aktif. Bisa beberapa menit kalau catatanmu banyak.';

  @override
  String get reindexStep2Action => 'Jalankan re-embed';

  @override
  String get reindexStep2Busy => 'Memproses…';

  @override
  String get reindexResetDialogTitle => 'Reset semua embedding?';

  @override
  String get reindexResetDialogBody =>
      'Semua catatanmu akan dikosongkan kolom embedding-nya. Asisten AI tidak akan bisa mencari catatan sampai langkah re-embed selesai.';

  @override
  String get reindexResetDialogConfirm => 'Reset';

  @override
  String get reindexConfirmCancel => 'Batal';

  @override
  String get reindexNotLoggedIn => 'Belum login';

  @override
  String get reindexResetDoneNudge =>
      'Embedding direset. Klik \"Jalankan re-embed\" sekarang.';

  @override
  String reindexResetFailed(String error) {
    return 'Reset gagal: $error';
  }

  @override
  String reindexRunFailed(String error) {
    return 'Re-embed gagal: $error';
  }

  @override
  String get reindexRunDone => 'Re-embed selesai.';

  @override
  String reindexRunDoneCount(Object count) {
    return '$count catatan diproses ulang.';
  }

  @override
  String reindexRunSkipped(int count) {
    return '$count dilewati karena belum ada judul atau isinya.';
  }

  @override
  String reindexRunErrors(int count) {
    return '$count gagal, coba jalankan lagi.';
  }

  @override
  String reindexStatusEmpty(int count) {
    return '$count catatan tanpa judul & isi tidak bisa diindeks.';
  }

  @override
  String get privacyAppBarTitle => 'PRIVASI';

  @override
  String get privacyTitle => 'Privasi\n& data.';

  @override
  String get privacyIntro =>
      'Catatanmu adalah milikmu. Kami menyimpan seminimal mungkin dan tidak menjual datamu ke pihak ketiga.';

  @override
  String get privacySectionGiven => 'YANG KAMU BERIKAN';

  @override
  String get privacyGiven1 =>
      'Email untuk masuk dan mengirim email penting (verifikasi, lupa sandi).';

  @override
  String get privacyGiven2 => 'Username yang ditampilkan di dashboard.';

  @override
  String get privacyGiven3 =>
      'Catatan: tautan, judul, isi manual, dan tag. Semua milikmu, bisa diakses dan dihapus kapan saja.';

  @override
  String get privacyGiven4 =>
      'Embedding catatan, yaitu vektor numerik yang dipakai fitur \"Asisten\" untuk mencari catatan terkait.';

  @override
  String get privacySectionWhere => 'DI MANA DISIMPAN';

  @override
  String get privacyWhereBody =>
      'Database Postgres + pgvector di Supabase (region Asia Tenggara). Semua koneksi melalui HTTPS. Setiap baris di-tag dengan ID pengguna dan dilindungi Row Level Security, jadi kamu hanya bisa membaca catatanmu sendiri. Salinan catatanmu juga disimpan di HP ini (di dalam aplikasi, hanya terbuka untuk akunmu) supaya tetap bisa dipakai saat offline; salinan itu hilang saat aplikasi dihapus.';

  @override
  String get privacySectionDont => 'YANG TIDAK KAMI LAKUKAN';

  @override
  String get privacyDont1 =>
      'Tidak ada pelacakan iklan atau analitik pihak ketiga.';

  @override
  String get privacyDont2 => 'Tidak ada penjualan data.';

  @override
  String get privacyDont3 =>
      'Tidak ada pengiriman catatanmu ke layanan eksternal selain untuk fitur AI yang kamu picu sendiri (mis. \"Tanya asisten\").';

  @override
  String get privacySectionRights => 'HAK KAMU';

  @override
  String get privacyRights1 =>
      'Edit atau hapus catatan kapan saja dari Pustaka.';

  @override
  String get privacyRights2 =>
      'Hapus akun dan semua catatan terkait. Tombolnya akan segera tersedia, sementara ini bisa diminta lewat kontak di bawah.';

  @override
  String get privacyRights3 => 'Minta salinan datamu dengan menghubungi kami.';

  @override
  String get privacySectionContact => 'KONTAK';

  @override
  String get privacyContactBody =>
      'Pertanyaan, permintaan ekspor, atau penghapusan data: hubungi TemanLabs lewat halaman Tentang IngatanKu.';

  @override
  String get aboutAppBarTitle => 'TENTANG';

  @override
  String get aboutTitle => 'Tentang\nIngatanKu.';

  @override
  String get aboutTagline => 'Peliharaan kecil yang tumbuh bersama ilmumu';

  @override
  String get aboutDescription =>
      'Simpan link dan video sekali. Peliharaanmu mencatatnya, melahapnya, lalu tumbuh, dan asistennya sudah kenal seluruh koleksimu.';

  @override
  String get aboutSectionMaker => 'DIBUAT OLEH';

  @override
  String get aboutMakerName => 'TemanLabs';

  @override
  String get aboutMakerRole => 'Pembuat IngatanKu';

  @override
  String get aboutMakerBody =>
      'Dibangun sepenuh hati untuk orang-orang yang penasaran dan ingin mengubah scroll harian jadi ingatan jangka panjang.';

  @override
  String get aboutSectionVersion => 'VERSI';

  @override
  String get aboutVersionLabel => 'rilis awal';

  @override
  String get aboutSectionThanks => 'TERIMA KASIH';

  @override
  String get aboutThanksBody =>
      'Untuk komunitas open-source dan setiap orang yang sudah mencoba IngatanKu sejak hari pertama.';

  @override
  String aboutCopyright(int year) {
    return '© $year TemanLabs';
  }

  @override
  String get weeklyQuizAppBarTitle => 'QUIZ MINGGUAN';

  @override
  String get weeklyQuizPageTitle => 'Quiz minggu ini.';

  @override
  String get weeklyQuizSubtitle =>
      'Lima pertanyaan dari catatan yang kamu simpan minggu ini. Pilih opsi untuk menjawab.';

  @override
  String get weeklyQuizGenerateCta => 'Buat quiz';

  @override
  String get weeklyQuizRetryCta => 'Coba lagi';

  @override
  String get weeklyQuizScoreLabel => 'Skor';

  @override
  String get weeklyQuizCorrectLabel => 'Benar';

  @override
  String get weeklyQuizExplanationLabel => 'Kenapa';

  @override
  String get weeklyQuizSourceLabel => 'Catatan sumber';

  @override
  String get weeklyQuizDoneTitle => 'Quiz selesai.';

  @override
  String get weeklyQuizDoneSubtitle =>
      'Mampir lagi minggu depan untuk set baru.';

  @override
  String get weeklyQuizNotEnoughNotes =>
      'Simpan minimal 3 catatan minggu ini buat unlock quiz.';

  @override
  String get weeklyQuizGenerating => 'Lagi nyusun quiz, beberapa detik aja.';

  @override
  String get weeklyQuizGenericError =>
      'Quiz nggak bisa dibuat. Coba lagi nanti.';

  @override
  String weeklyQuizQuestionProgress(int current, int total) {
    return 'PERTANYAAN $current / $total';
  }

  @override
  String get weeklyQuizReviewBadge => 'REVIEW';

  @override
  String get weeklyQuizCheckCta => 'PERIKSA';

  @override
  String get weeklyQuizNextCta => 'LANJUT';

  @override
  String get weeklyQuizFinishCta => 'SELESAI';

  @override
  String get weeklyQuizSubmitCta => 'SELESAIKAN QUIZ';

  @override
  String get weeklyQuizSubmittingCta => 'MEMPROSES…';

  @override
  String get weeklyQuizPrevCta => 'KEMBALI';

  @override
  String get weeklyQuizCorrectBadge => 'BENAR';

  @override
  String get weeklyQuizWrongBadge => 'KELIRU';

  @override
  String get weeklyQuizScoreEyebrow => 'SKOR MINGGU INI';

  @override
  String get weeklyQuizResultPerfect =>
      'Sempurna! Catatan kamu betul-betul nempel.';

  @override
  String get weeklyQuizResultGood =>
      'Bagus, mayoritas materi terserap dengan baik.';

  @override
  String get weeklyQuizResultRetry =>
      'Mari ulang catatan-catatan yang masih lemah.';

  @override
  String get weeklyQuizSummaryEyebrow => 'RINCIAN';

  @override
  String get weeklyQuizCloseCta => 'TUTUP';

  @override
  String get weeklyQuizReviewCta => 'LIHAT JAWABAN';

  @override
  String get weeklyQuizLoadingMessage =>
      'Membuat quiz dari catatan minggu ini…';

  @override
  String get weeklyQuizErrorRetryCta => 'COBA LAGI';

  @override
  String get chatAppBarTitle => 'TANYA ASISTENMU';

  @override
  String get chatPageTitle => 'Tanya\nasistenmu.';

  @override
  String get chatSubtitle =>
      'AI akan mencari di seluruh catatan yang sudah kamu simpan dan menjawab dengan referensi langsung.';

  @override
  String get chatTrySection => 'COBA TANYA';

  @override
  String chatInputHint(String name) {
    return 'Tanya $name tentang catatanmu…';
  }

  @override
  String chatTitle(String name) {
    return 'Tanya $name';
  }

  @override
  String get chatResetTooltip => 'Mulai sesi baru';

  @override
  String get tagChipHint => 'Tambahkan tag, tekan enter';

  @override
  String get tagChipSuggestionsLabel => 'SARAN';

  @override
  String get timeAgoJustNow => 'baru saja';

  @override
  String timeAgoMinutes(int count) {
    return '$count mnt';
  }

  @override
  String timeAgoHours(int count) {
    return '$count jam';
  }

  @override
  String timeAgoDays(int count) {
    return '$count hari';
  }

  @override
  String timeAgoWeeks(int count) {
    return '$count minggu';
  }

  @override
  String get monthShortJan => 'Jan';

  @override
  String get monthShortFeb => 'Feb';

  @override
  String get monthShortMar => 'Mar';

  @override
  String get monthShortApr => 'Apr';

  @override
  String get monthShortMay => 'Mei';

  @override
  String get monthShortJun => 'Jun';

  @override
  String get monthShortJul => 'Jul';

  @override
  String get monthShortAug => 'Agt';

  @override
  String get monthShortSep => 'Sep';

  @override
  String get monthShortOct => 'Okt';

  @override
  String get monthShortNov => 'Nov';

  @override
  String get monthShortDec => 'Des';

  @override
  String get dayShortSun => 'MINGGU';

  @override
  String get dayShortMon => 'SENIN';

  @override
  String get dayShortTue => 'SELASA';

  @override
  String get dayShortWed => 'RABU';

  @override
  String get dayShortThu => 'KAMIS';

  @override
  String get dayShortFri => 'JUMAT';

  @override
  String get dayShortSat => 'SABTU';

  @override
  String get monthShortUpperJan => 'JAN';

  @override
  String get monthShortUpperFeb => 'FEB';

  @override
  String get monthShortUpperMar => 'MAR';

  @override
  String get monthShortUpperApr => 'APR';

  @override
  String get monthShortUpperMay => 'MEI';

  @override
  String get monthShortUpperJun => 'JUN';

  @override
  String get monthShortUpperJul => 'JUL';

  @override
  String get monthShortUpperAug => 'AGT';

  @override
  String get monthShortUpperSep => 'SEP';

  @override
  String get monthShortUpperOct => 'OKT';

  @override
  String get monthShortUpperNov => 'NOV';

  @override
  String get monthShortUpperDec => 'DES';

  @override
  String get tagsPageEyebrow => 'KELOLA TAG';

  @override
  String get tagsPageTitle => 'Tag.';

  @override
  String tagsPageSummary(int tagCount, int noteCount) {
    return '$tagCount tag · $noteCount catatan';
  }

  @override
  String tagsRowNoteCount(int count) {
    return '$count catatan';
  }

  @override
  String get tagsEditTooltip => 'Ubah nama tag';

  @override
  String get tagsDeleteTooltip => 'Hapus tag';

  @override
  String get tagsRenameDialogTitle => 'Ubah nama tag';

  @override
  String get tagsRenameDialogHint => 'Nama tag baru';

  @override
  String get tagsRenameDialogCancel => 'Batal';

  @override
  String get tagsRenameDialogConfirm => 'Simpan';

  @override
  String get tagsDeleteDialogTitle => 'Hapus tag?';

  @override
  String get tagsDeleteDialogBody =>
      'Tag akan dihapus dari semua catatan terkait.';

  @override
  String get tagsDeleteDialogCancel => 'Batal';

  @override
  String get tagsDeleteDialogConfirm => 'Hapus';

  @override
  String get tagDetailEyebrow => 'TAG';

  @override
  String tagDetailNoteCount(int count) {
    return '$count catatan terkait';
  }

  @override
  String get tagDetailEmpty => 'Belum ada catatan dengan tag ini.';

  @override
  String get sourceLabelArticle => 'Artikel';

  @override
  String get quizSelfRatingPrompt => 'Seberapa kamu paham soal ini?';

  @override
  String get quizSelfRatingEasy => 'Mudah';

  @override
  String get quizSelfRatingMedium => 'Pas';

  @override
  String get quizSelfRatingHard => 'Sulit';

  @override
  String get quizResultHardCarryNone =>
      'Mantap. Tidak ada soal yang perlu kamu review minggu depan.';

  @override
  String quizResultHardCarry(int count) {
    return '$count soal sulit akan muncul lagi minggu depan sebagai refresher.';
  }

  @override
  String get homeActionWardrobe => 'Lemari';

  @override
  String get petDefaultName => 'Bolubi';

  @override
  String petSemantics(String name) {
    return '$name, peliharaanmu. Usap untuk mengelus; tap berarti memukul.';
  }

  @override
  String get petMeterFullness => 'Kenyang';

  @override
  String get petMeterHappiness => 'Senang';

  @override
  String get petMeterGrowth => 'Tumbuh';

  @override
  String get petStageEgg => 'Telur';

  @override
  String get petStageBaby => 'Bayi';

  @override
  String get petStageKid => 'Anak';

  @override
  String get petStageTeen => 'Remaja';

  @override
  String get petStageAdult => 'Dewasa';

  @override
  String get petStageSage => 'Bijak';

  @override
  String petGrowthNext(String stage) {
    return 'Menuju $stage';
  }

  @override
  String get petGrowthMax => 'Sudah tahap tertinggi';

  @override
  String get petFoodBento => 'Bento';

  @override
  String get petFoodSandwich => 'Roti lapis';

  @override
  String get petFoodOnigiri => 'Onigiri';

  @override
  String get petFoodDonut => 'Donat';

  @override
  String get petFoodCookie => 'Kue';

  @override
  String get petFoodChips => 'Keripik';

  @override
  String petWardrobeTitle(String name) {
    return 'Lemari $name';
  }

  @override
  String get petNameLabel => 'NAMA';

  @override
  String get petNamingTitle => 'Kasih dia nama';

  @override
  String get petNamingBody =>
      'Nama ini dipakai di rumahnya dan saat dia menjawab pertanyaanmu. Bisa diganti kapan saja dari profilnya.';

  @override
  String get petNamingSave => 'Simpan nama';

  @override
  String get petColorLabel => 'WARNA';

  @override
  String get petAccessoryLabel => 'AKSESORI';

  @override
  String petLocked(String name, String stage) {
    return 'Terbuka saat $name jadi $stage.';
  }

  @override
  String get petStatAge => 'UMUR';

  @override
  String get petStatCare => 'DIRAWAT';

  @override
  String get petStatDigested => 'DICERNA';

  @override
  String get petStatPets => 'DIELUS';

  @override
  String petStatDays(int days) {
    return '$days hr';
  }

  @override
  String petStatCareSemantics(int days) {
    return 'Disuapi $days hari berturut-turut';
  }

  @override
  String get petColorMatcha => 'Matcha';

  @override
  String get petColorPeach => 'Persik';

  @override
  String get petColorSky => 'Langit';

  @override
  String get petColorTaro => 'Talas';

  @override
  String get petColorHoney => 'Madu';

  @override
  String get petColorMocha => 'Kopi';

  @override
  String get petColorMochi => 'Mochi';

  @override
  String get petAccessoryNone => 'Polos';

  @override
  String get petAccessorySprout => 'Tunas';

  @override
  String get petAccessoryBow => 'Pita';

  @override
  String get petAccessoryGlasses => 'Kacamata';

  @override
  String get petAccessoryScarf => 'Syal';

  @override
  String get petAccessoryBeanie => 'Kupluk';

  @override
  String get petAccessoryHeadphones => 'Headphone';

  @override
  String get petAccessoryCrown => 'Mahkota';

  @override
  String get petAccessoryChefHat => 'Topi koki';

  @override
  String get petAccessoryPartyHat => 'Topi pesta';

  @override
  String get petAccessoryCatEars => 'Telinga kucing';

  @override
  String get petAccessoryFlower => 'Bunga';

  @override
  String get petAccessoryPeci => 'Peci';

  @override
  String get petAccessoryWitchHat => 'Topi penyihir';

  @override
  String get petAccessorySantaHat => 'Topi Santa';

  @override
  String get petOutfitLabel => 'OUTFIT';

  @override
  String get petOutfitNone => 'Tanpa outfit';

  @override
  String get petOutfitHoodie => 'Hoodie';

  @override
  String get petOutfitStripedTee => 'Kaos belang';

  @override
  String get petOutfitOveralls => 'Overall';

  @override
  String get petOutfitSweater => 'Sweter rajut';

  @override
  String get petOutfitBatik => 'Batik';

  @override
  String get petOutfitDino => 'Kostum dino';

  @override
  String get petOutfitFrog => 'Kostum katak';

  @override
  String get petOutfitBee => 'Kostum lebah';

  @override
  String get petOutfitAstronaut => 'Astronaut';

  @override
  String get petOutfitRaincoat => 'Jas hujan';

  @override
  String get petOutfitKoko => 'Baju koko';

  @override
  String get petOutfitPumpkin => 'Kostum labu';

  @override
  String get petOutfitGroupEveryday => 'Harian';

  @override
  String get petOutfitGroupCostume => 'Kostum';

  @override
  String get petOutfitGroupSeasonal => 'Musiman';

  @override
  String get petPremiumBadge => 'Premium';

  @override
  String get shopTitle => 'Butik';

  @override
  String get shopTooltip => 'Butik: aksesori & outfit';

  @override
  String get shopTakeOff => 'Lepas';

  @override
  String get shopShelfAll => 'Semua';

  @override
  String get shopShelfHats => 'Aksesori';

  @override
  String get shopPetLine1 => 'Mau coba yang mana?';

  @override
  String get shopPetLine2 => 'Ketuk baju di bawah, aku coba-in.';

  @override
  String get shopPetPetted => 'Hehe, jangan dikusutin bajunya!';

  @override
  String get shopPetReact1 => 'Cocok nggak?';

  @override
  String get shopPetReact2 => 'Lucu kan?';

  @override
  String get shopPetReact3 => 'Aku suka yang ini!';

  @override
  String get shopPetMirror => 'Hmm, bagus juga…';

  @override
  String get shopBarSoon => 'Bisa dibeli segera';

  @override
  String get shopOwned => 'Punyamu';

  @override
  String get shopWear => 'Pakai';

  @override
  String get shopWearing => 'Sedang dipakai';

  @override
  String get wardrobeShopCta => 'Mau tampil beda? Mampir ke Butik';

  @override
  String get vaultRowDigested => 'Dicerna';

  @override
  String profileRoomTitle(String name) {
    return 'Kamar $name';
  }

  @override
  String get homeTodayTitle => 'Tersimpan hari ini';

  @override
  String homeTodayRange(int from, int to, int total) {
    return '$from–$to dari $total';
  }

  @override
  String get homeTodayOpenLibrary => 'Buka Pustaka';

  @override
  String get homeRest => 'Tidurkan';

  @override
  String get homeWake => 'Bangunkan';

  @override
  String get homeQuickSaveHint => 'Tempel link di sini…';

  @override
  String get homeQuickSaveSend => 'Catat';

  @override
  String get homeQuickSavePaste => 'Tempel dari clipboard';

  @override
  String get petStatusEgg =>
      'Telurnya hangat… simpan link pertamamu supaya menetas.';

  @override
  String get petStatusReady => 'Siap jaga catatanmu';

  @override
  String get petStatusHappy => 'Kenyang dan senang';

  @override
  String get petStatusHungry => 'Lapar ilmu… ada link baru?';

  @override
  String get petStatusLonely => 'Agak kesepian, elus sebentar?';

  @override
  String get petStatusResting => 'Tidur sebentar di bantalnya…';

  @override
  String get petStatusWoke => 'Eh, sudah bangun!';

  @override
  String get petStatusPetted => 'Senang dielus';

  @override
  String get petStatusPlayed => 'Wiii, main lagi!';

  @override
  String get petStatusNewLink => 'Wah, ada ilmu baru!';

  @override
  String get petStatusAte => 'Nyam! Cemilan yang enak.';

  @override
  String petStatusAteMany(int count) {
    return 'Nyam! $count cemilan enak.';
  }

  @override
  String get petStatusFull => 'Kenyang… kusimpan untuk nanti.';

  @override
  String petStatusHatched(String name) {
    return 'Halo! Aku $name. Terima kasih ilmu pertamanya!';
  }

  @override
  String petStatusEvolved(String stage) {
    return 'Aku tumbuh jadi $stage!';
  }

  @override
  String get petStatusNotLink => 'Hmm, itu bukan link.';

  @override
  String get petStatusClipboardEmpty => 'Clipboard-mu kosong.';

  @override
  String get petStatusSaveFailed => 'Gagal menyimpan. Coba lagi, ya.';

  @override
  String get petStatusNothingToday => 'Belum ada yang tersimpan hari ini.';

  @override
  String get vaultAll => 'Semua';

  @override
  String get vaultGroupToday => 'Hari ini';

  @override
  String get vaultGroupYesterday => 'Kemarin';

  @override
  String get vaultGroupWeek => 'Minggu ini';

  @override
  String get vaultGroupOlder => 'Lebih lama';

  @override
  String get vaultUntitled => '(Tanpa judul)';

  @override
  String get vaultRowNotDigested => 'Belum dicerna';

  @override
  String get homeTvCaption => 'tersimpan hari ini';

  @override
  String get notesPetEmpty =>
      'Bukuku masih kosong. Tulis catatan pertama, yuk!';

  @override
  String notesPetWriting(int count) {
    return 'Lagi nyatet… sudah $count catatan.';
  }

  @override
  String get notesPetCopying => 'Psst, aku lagi menyalin ide-idemu.';

  @override
  String get notesPetPetted => 'Hehe, hati-hati, aku lagi nulis!';

  @override
  String get libraryPetEmpty =>
      'Rakku masih kosong. Simpan link pertamamu, ya!';

  @override
  String libraryPetCount(int count) {
    return '$count ilmu tersimpan di rakku.';
  }

  @override
  String libraryPetReading(String title) {
    return 'Lagi baca “$title”…';
  }

  @override
  String get chatPetIdle =>
      'Tanya apa saja — aku jawab dari catatan yang sudah kumakan.';

  @override
  String get chatPetAnswering => 'Begini yang kuingat…';

  @override
  String get chatPetDone => 'Semoga membantu! Mau tanya lagi?';

  @override
  String get chatPetError => 'Waduh, aku lupa mau bilang apa. Coba lagi, ya?';

  @override
  String get chatPetPetted => 'Hehe, aku dengerin kok.';

  @override
  String get petStatusLifted => 'Eh, eh! Turunin aku!';

  @override
  String get petStatusDizzy => 'Pusiiing…';

  @override
  String get petStatusGrumpy => 'Hmph! Jangan dijatuhin gitu dong!';

  @override
  String get petStatusPutDown => 'Hmph… pelan-pelan dong.';

  @override
  String get libraryPetShush => 'Ssst! Ini perpustakaan, jangan berisik.';

  @override
  String get libraryPetAngry => 'Ihh! Aku lagi baca, jangan diganggu!';

  @override
  String get petStatusSharedLink =>
      'Ada link masuk! Ketuk centang, nanti aku catat.';

  @override
  String get petScribeStart => 'Bentar, aku catat dulu ya…';

  @override
  String petScribeFound(String label) {
    return 'Ketemu $label, lagi aku tulis…';
  }

  @override
  String get petScribeDone => 'Taraa! Ini catatanku.';

  @override
  String get petScribePartial =>
      'Isinya nggak kebaca semua, tapi ini catatanku.';

  @override
  String get petScribeOutOfQuota =>
      'Jatah nulisku hari ini sudah habis. Kamu isi sendiri dulu ya?';

  @override
  String get petScribeCancelled => 'Oke, linknya aku taruh sini dulu.';

  @override
  String scribeSheetEyebrow(String name) {
    return 'Catatan $name';
  }

  @override
  String get scribeSheetTitle => 'Cek dulu sebelum aku makan';

  @override
  String get scribeSheetNoSummary =>
      'Aku belum bisa merangkum isinya — tulis sendiri kalau mau.';

  @override
  String get scribeSheetOutOfQuota =>
      'Jatah ringkasanku hari ini sudah habis — tulis sendiri dulu, atau bagikan lagi besok.';

  @override
  String scribeSheetSave(String name) {
    return 'Simpan & suapi $name';
  }

  @override
  String get petStatusQuizReady =>
      'Aku lapar! Makan hari ini sudah siap di bawah.';

  @override
  String get homeShelfSemantics => 'Rak buku — buka koleksimu';

  @override
  String get petIdleTv => 'Wah, ada apa di TV?';

  @override
  String get petIdleShelf => 'Hmm, baca buku apa ya…';

  @override
  String get petIdleYawn => 'Hoaam…';

  @override
  String get petIdleDance => 'Joget dikit!';

  @override
  String get petIdleSneeze => 'Hachiu!';

  @override
  String get petIdleWave => 'Haii!';

  @override
  String get petStatusHowTo =>
      'Usap aku buat ngelus, angkat aku, atau suapi aku link!';

  @override
  String get petWardrobeHint => 'Warna dan aksesori untuk dicoba.';

  @override
  String get petVitalsLabel => 'KONDISI';

  @override
  String get petStatsLabel => 'PERJALANANNYA';

  @override
  String get petStatusBonk => 'Aduh! Kok dipukul sih?';

  @override
  String get petStatusBonkAngry => 'Ihh! Berhenti mukulin aku!';

  @override
  String get petStatusCry => 'Huwaaa… sakiiit! Elus aku dulu…';

  @override
  String get petStatusCrySoothe => 'Hiks… hiks…';

  @override
  String get petStatusComforted => 'Makasih… tapi jangan pukul aku lagi ya.';

  @override
  String get petIdleRoll => 'Wiii~ guling-guling!';

  @override
  String get petIdleRollBack => 'Hehe, aku balik!';

  @override
  String get petStatusMosquito => 'Eh, ada nyamuk!';

  @override
  String get petStatusMosquitoChase => 'Sini kamu!';

  @override
  String get petStatusMosquitoCaught => 'Hap! Ketangkep~';

  @override
  String get petStatusMosquitoAfter => 'Hmm… nggak bikin kenyang sih.';

  @override
  String homeBoardSemantics(int count) {
    return 'Papan: $count tersimpan hari ini. Ketuk untuk melihat.';
  }

  @override
  String get homeTvChannel => 'TV — ketuk untuk ganti saluran';

  @override
  String homeHouseTitle(String name) {
    return 'Rumah $name';
  }

  @override
  String get homeGreetNight => 'Selamat malam';

  @override
  String get homeGeckoChirp => 'cek cek cek';

  @override
  String get petStatusGecko => 'Eh, ada cicak!';

  @override
  String homeClockSemantics(String time) {
    return 'Jam, $time';
  }

  @override
  String homePetInfo(String name) {
    return '$name — lihat info';
  }

  @override
  String get homeInbox => 'Kabar';

  @override
  String get homeInboxUnread => 'Kabar — ada yang baru';

  @override
  String get petStatusFeedMe => 'Tempel link di bawah, aku lapar!';

  @override
  String inboxTitle(String name) {
    return 'Kabar dari $name';
  }

  @override
  String get inboxEmptyTitle => 'Belum ada kabar';

  @override
  String inboxEmptyBody(String name) {
    return '$name akan kabari kamu di sini.';
  }

  @override
  String get inboxNow => 'Sekarang';

  @override
  String inboxMinutesAgo(int count) {
    return '$count mnt lalu';
  }

  @override
  String inboxHoursAgo(int count) {
    return '$count jam lalu';
  }

  @override
  String get inboxYesterday => 'Kemarin';

  @override
  String inboxDaysAgo(int count) {
    return '$count hari lalu';
  }

  @override
  String noticeHungryTitle(String name) {
    return '$name lapar';
  }

  @override
  String get noticeHungryBody =>
      'Kuis hari ini adalah makanannya — tiga soal singkat.';

  @override
  String noticeLonelyTitle(String name) {
    return '$name agak kesepian';
  }

  @override
  String get noticeLonelyBody => 'Usap-usap sebentar, yuk.';

  @override
  String get noticeUnfedTitle => 'Hari ini belum makan';

  @override
  String noticeUnfedBody(int count) {
    return 'Jaga $count hari dirawat — selesaikan kuis hari ini.';
  }

  @override
  String get noticeQuizTitle => 'Makan hari ini sudah siap';

  @override
  String get noticeQuizBody => 'Tiga soal singkat dari catatanmu.';

  @override
  String noticeHatchedTitle(String name) {
    return '$name menetas!';
  }

  @override
  String get noticeHatchedBody => 'Sapa dia, lalu suapi ilmu pertamamu.';

  @override
  String noticeEvolvedTitle(String name, String stage) {
    return '$name tumbuh jadi $stage';
  }

  @override
  String get noticeEvolvedBody =>
      'Mungkin ada aksesori baru yang terbuka di lemari.';

  @override
  String noticeStreakTitle(int count) {
    return '$count hari dirawat!';
  }

  @override
  String noticeStreakBody(String name) {
    return '$name senang kamu rajin datang.';
  }

  @override
  String get profileSoundEffects => 'Efek suara';

  @override
  String get profileRoomAmbience => 'Suasana ruangan';

  @override
  String get profileBackgroundMusic => 'Musik latar';

  @override
  String get profileGroupSound => 'Suara';

  @override
  String get profileGroupYou => 'Kamu';

  @override
  String get profileGroupNotes => 'Catatan & pustaka';

  @override
  String get profileGroupMore => 'Lainnya';

  @override
  String get profileSoundOn => 'Nyala';

  @override
  String get profileSoundOff => 'Mati';

  @override
  String get profileLanguageInUse => 'Dipakai';

  @override
  String get profileLanguagePick => 'Pilih';

  @override
  String get noteEditorNewTitle => 'Catatan baru';

  @override
  String get noteEditorEditTitle => 'Ubah catatan';

  @override
  String get noteEditorAutoSave => 'Tersimpan otomatis';

  @override
  String get noteEditorSaving => 'Menyimpan…';

  @override
  String get onboardSkip => 'Lewati';

  @override
  String get onboardNext => 'Lanjut';

  @override
  String get onboardStart => 'Ayo mulai';

  @override
  String get onboardMeetTitle => 'Kenalan sama\npeliharaanmu.';

  @override
  String get onboardMeetBody =>
      'Dia masih di dalam telur, dan cuma makan satu hal: ilmu yang kamu pelajari.';

  @override
  String get onboardFeedTitle => 'Suapi dengan\ntemuanmu.';

  @override
  String get onboardFeedBody =>
      'Bagikan video atau tempel link. Peliharaanmu mencatat judul, ringkasan, dan tag-nya, lalu menyantapnya sebagai cemilan.';

  @override
  String get onboardGrowTitle => 'Lihat dia\ntumbuh besar.';

  @override
  String get onboardGrowBody =>
      'Setiap catatan bikin dia tumbuh, dari telur mungil sampai jadi bijak. Jaga dia tetap kenyang dan senang!';

  @override
  String get onboardAskTitle => 'Tanya, lalu\nuji dirimu.';

  @override
  String get onboardAskBody =>
      'Makanan utamanya adalah kuis 3 soal dari catatanmu setiap hari, jadi yang kamu simpan benar-benar nempel. Kamu juga bisa tanya asisten apa saja.';

  @override
  String get onboardAskBubble => 'Tanya aku apa saja!';

  @override
  String get chatSourcesLabel => 'DARI CATATANMU';

  @override
  String get tagsEmptyEyebrow => 'TAG KOSONG';

  @override
  String get tagsEmptyTitle => 'Belum\nada tag.';

  @override
  String get tagsEmptyBody =>
      'Tag akan muncul di sini setelah kamu menambahkannya ke catatan. Tambahkan tag saat menyimpan atau mengedit catatan.';

  @override
  String get notesIdleSip => 'Istirahat minum teh dulu.';

  @override
  String get notesIdleThink => 'Hmm… gimana nulisnya ya?';

  @override
  String get notesIdleIdea => 'Oh! Ketemu.';

  @override
  String get notesIdleBoard => 'Cek papan dulu.';

  @override
  String get notesIdleDoze => 'Eh? Aku bangun kok!';

  @override
  String get libraryIdleDoze => 'Zz… cuma ngistirahatin mata.';

  @override
  String get libraryIdleGiggle => 'Hehe, bagian ini lucu.';

  @override
  String get libraryIdleSneeze => 'Hachiu! Bukunya berdebu.';

  @override
  String get chatIdleSip => 'Mm, tehnya masih hangat.';

  @override
  String visitHello(String name) {
    return 'Halo, $name!';
  }

  @override
  String visitHelloBack(String name) {
    return 'Eh, $name! Halo!';
  }

  @override
  String get visitAskFood => 'Hari ini makan apa?';

  @override
  String get visitAskLearn => 'Hari ini belajar apa?';

  @override
  String get visitAskRoom => 'Kamarmu nyaman banget!';

  @override
  String visitReplyAte(int count) {
    return '$count catatan, enak semua!';
  }

  @override
  String get visitReplyHungry => 'Belum ada… lapar nih.';

  @override
  String get visitReplyRoom => 'Makasih! Mampir aja kapan-kapan.';

  @override
  String get visitWow => 'Wah, iri deh!';

  @override
  String get visitAww => 'Yah, semoga cepat disuapi ya.';

  @override
  String get visitBye => 'Aku pamit ya, dadah!';

  @override
  String get visitByeBack => 'Dadah!';

  @override
  String visitSemantics(String name) {
    return '$name, teman yang mampir';
  }

  @override
  String homeCalendarToday(String date) {
    return 'Hari ini $date.';
  }

  @override
  String get petStatusSnackEnough =>
      'Cemilannya cukup dulu, aku simpan tempat buat makan dari kuis!';

  @override
  String petStatusMealLocked(int count) {
    return 'Simpan $count catatan dulu, nanti aku bisa makan dari kuis!';
  }

  @override
  String get homeMealReady => 'Makan hari ini';

  @override
  String get homeMealReadySub => '3 soal singkat';

  @override
  String get homeFeastReady => 'Pesta mingguan';

  @override
  String get homeFeastReadySub => 'Kuis panjang, tumbuh pesat';

  @override
  String get homeMealDone => 'Sudah makan hari ini';

  @override
  String get homeMealLocked => 'Makan segera dibuka';

  @override
  String homeMealLockedSub(int count, int need) {
    return '$count/$need catatan tersimpan';
  }

  @override
  String get quizMealTitle => 'MAKAN HARI INI';

  @override
  String get quizFeastTitle => 'PESTA MINGGUAN';

  @override
  String get quizMealLoading => 'Menyiapkan makan hari ini…';

  @override
  String quizGainFull(int count) {
    return '+$count kenyang';
  }

  @override
  String quizGainGrowth(int count) {
    return '+$count tumbuh';
  }

  @override
  String quizResultHardCarryDaily(int count) {
    return '$count soal sulit akan muncul lagi besok.';
  }

  @override
  String get quizResultHardCarryNoneDaily =>
      'Beres — tidak ada soal sulit yang perlu diulang.';

  @override
  String get petStatusFullRefuse =>
      'Nggak ah, aku udah kenyang! Kalau cemilan sih mau — simpan catatan baru.';

  @override
  String get petStatusFeastNudge =>
      'Kalau mau aku cepat tumbuh, kerjain kuis pesta mingguannya ya!';

  @override
  String petStatusFeastLocked(int count) {
    return 'Simpan $count catatan minggu ini dulu, nanti kita pesta!';
  }

  @override
  String get quizPetStart => 'Waktunya makan! Ayo mulai.';

  @override
  String get quizPetFeastStart => 'Waktunya pesta! Aku lapar banget.';

  @override
  String get quizPetLast => 'Suapan terakhir!';

  @override
  String get quizPetPicked => 'Ooh, yang itu ya?';

  @override
  String get quizPetHurry => 'Buruan dong, laper nih!';

  @override
  String get quizPetHurryAgain => 'Perutku udah keroncongan…';

  @override
  String get quizPetYum => 'Nyam, enak banget!';

  @override
  String get quizPetYuck => 'Hmm… rasanya agak aneh.';

  @override
  String get quizPetBurp => '*Ehk!* Eh, maaf.';

  @override
  String get quizPetFull => 'Kenyang banget… makasih!';

  @override
  String get quizPetDoneGood => 'Makanan yang enak!';

  @override
  String get quizPetDoneMeh => 'Masih agak lapar… belajar lagi yuk!';

  @override
  String get libraryPetTease => 'Yakin kamu bisa bikin aku kenyang hari ini?';

  @override
  String get libraryPetTeaseFed => 'Cuma segitu? Besok aku mau lebih banyak.';

  @override
  String offlineNeedInternet(String what) {
    return 'Aku butuh internet buat $what. Nyalakan WiFi atau data dulu, ya!';
  }

  @override
  String get offlineWhatAssistant => 'mikirin jawabannya';

  @override
  String get offlineWhatMealQuiz => 'nyiapin kuis hari ini';

  @override
  String get offlineWhatFeastQuiz => 'nyiapin pesta mingguan';

  @override
  String get offlineWhatSummary => 'baca dan ringkas link-nya';

  @override
  String get offlineWhatPreview => 'ngintip isi link-nya';

  @override
  String get offlineWhatVideo => 'muter videonya';

  @override
  String get offlineWhatDownload => 'ngunduh videonya';

  @override
  String get offlineWhatReindex => 'ngindeks ulang catatanmu';

  @override
  String get offlineWhatAccount => 'ngubah akunmu';

  @override
  String get offlineWhatSignUp => 'bikin akunmu';

  @override
  String get offlineWhatSignIn => 'masuk ke akunmu';

  @override
  String get offlineSafeNote =>
      'Catatanmu tetap aman di HP, dan tersinkron sendiri begitu online lagi.';

  @override
  String get offlineBackOnline => 'Yeay, sudah online lagi!';

  @override
  String get offlineStill => 'Masih offline nih… coba lagi sebentar lagi?';

  @override
  String get offlineOk => 'Oke';

  @override
  String get offlineRetry => 'Coba lagi';

  @override
  String get offlineContinue => 'Lanjut';

  @override
  String get offlineTag => 'Offline';

  @override
  String get petStatusOfflineSaved =>
      'Lagi offline, jadi belum bisa kuringkas. Link-nya kusimpan dulu, ya!';

  @override
  String get petStatusWentOffline =>
      'Kita lagi offline. Catatan tetap bisa disimpan, kok, kujaga baik-baik!';

  @override
  String get petStatusBackOnline =>
      'Online lagi! Catatanmu kukirim ke akunmu, ya.';

  @override
  String get petStatusCoinsFalling =>
      'Eeeh, uangku jatuh! Jangan digoyang-goyang!';

  @override
  String get petStatusCoinsGather => 'Eh eh, koinku! Koinku!';

  @override
  String petStatusCoinsCounted(int count) {
    return '$count koin, lengkap! Jangan curi uangku, ya!';
  }

  @override
  String get petStatusCoinsMine => 'Jangan curi uangku!';

  @override
  String get petStatusCoinsSavings =>
      'Itu tabunganku, tahu! Awas kalau diambil!';

  @override
  String noteDetailPageOf(int position, int count) {
    return 'Halaman $position dari $count';
  }

  @override
  String get noteDetailPrevPage => 'Halaman sebelumnya';

  @override
  String get noteDetailNextPage => 'Halaman berikutnya';

  @override
  String get avatarPickerTitle => 'Pilih avatarmu';

  @override
  String get avatarPickerBody => 'Hewan kecil yang mewakili dirimu.';

  @override
  String get avatarPickerUse => 'Pakai avatar ini';

  @override
  String get accountCardEyebrow => 'Kartu anggota';

  @override
  String get accountChangeAvatar => 'Ganti avatar';

  @override
  String get avatarCat => 'Kucing';

  @override
  String get avatarDog => 'Anjing';

  @override
  String get avatarBear => 'Beruang';

  @override
  String get avatarBunny => 'Kelinci';

  @override
  String get avatarPanda => 'Panda';

  @override
  String get avatarFox => 'Rubah';

  @override
  String get avatarFrog => 'Katak';

  @override
  String get avatarOwl => 'Burung hantu';

  @override
  String get avatarKoala => 'Koala';

  @override
  String get avatarPig => 'Babi';

  @override
  String get avatarPenguin => 'Penguin';

  @override
  String get avatarLion => 'Singa';

  @override
  String get petIdleTour => 'Keliling ruangan dulu ah~';

  @override
  String get petIdleTourLook => 'Hmm, di sini ada apa ya…';

  @override
  String get petIdleTourDone => 'Udah keliling! Rumahku rapi juga ya.';

  @override
  String get petIdleShelfAfter =>
      'Bukunya nanti aja deh, nunggu kamu yang baca. Hehe~';

  @override
  String get petIdleTvAfter =>
      'Ah, nggak ada yang menarik. Nonton TV udah nggak seru deh.';

  @override
  String get petIdleFull => 'Hehe, kenyang dan senang~';

  @override
  String get petIdleHum => 'La la la~ ♪';

  @override
  String get coachNext => 'Lanjut';

  @override
  String get coachSkip => 'Lewati';

  @override
  String get coachDone => 'Mengerti';

  @override
  String quizCoachFeed(String name) {
    return 'Mulai sekarang kamu bisa kasih makan $name setiap hari! Makanannya kuis 3 soal dari catatanmu.';
  }

  @override
  String get quizCoachAnswer =>
      'Pilih jawabanmu, lalu tekan Periksa. Jawaban benar jadi makanan enak; yang salah tetap dimakan, tapi rasanya aneh.';

  @override
  String quizCoachSteps(String name) {
    return 'Habiskan ketiga soal supaya $name kenyang. Besok ada soal baru lagi.';
  }

  @override
  String get homeCoachEgg =>
      'Tempel link pertamamu di sini supaya telurnya menetas.';

  @override
  String homeCoachSave(String name) {
    return 'Tiap link yang kamu simpan jadi camilan $name. Tempel di sini kapan saja.';
  }

  @override
  String homeCoachMeal(String name) {
    return 'Ini makan harian $name. Setelah ada 3 catatan, ketuk untuk menjawab kuis hari ini.';
  }

  @override
  String homeCoachFeast(String name) {
    return 'Pesta mingguan: kuis lebih panjang dari catatan seminggu terakhir. Bikin $name cepat besar.';
  }

  @override
  String homeCoachVitals(String name) {
    return 'Kenyang, senang, dan tumbuhnya $name kelihatan di sini. Ketuk namanya untuk melihat profilnya.';
  }

  @override
  String get homeCoachShare =>
      'Lebih praktis lagi: di YouTube, TikTok, atau Instagram, ketuk Bagikan lalu pilih IngatanKu. Tidak perlu salin link.';

  @override
  String get coachShareTap => 'Bagikan';

  @override
  String get widgetEggTitle => 'Telurnya menunggu';

  @override
  String widgetEggBody(String name) {
    return 'Simpan link pertamamu supaya $name menetas.';
  }

  @override
  String widgetLockedTitle(String name) {
    return '$name lagi ngemil';
  }

  @override
  String get widgetLockedBody =>
      'Simpan 3 catatan untuk membuka kuis hariannya.';

  @override
  String widgetReadyTitle(String name) {
    return '$name lapar!';
  }

  @override
  String get widgetReadyBody => 'Kuis hari ini sudah siap, cuma 3 soal.';

  @override
  String widgetLateTitle(String name) {
    return '$name masih menunggu…';
  }

  @override
  String get widgetLateBody => 'Belum makan dari pagi. Masih sempat kok!';

  @override
  String widgetFullTitle(String name) {
    return '$name kenyang';
  }

  @override
  String get widgetFullBody => 'Makan hari ini beres. Sampai besok!';

  @override
  String get widgetFeed => 'Kasih makan';

  @override
  String get widgetSave => 'Simpan link';

  @override
  String widgetStreak(int days) {
    return '$days hari beruntun';
  }

  @override
  String get authContinueGoogle => 'Lanjutkan dengan Google';

  @override
  String get authGoogleFailed => 'Gagal masuk dengan Google. Coba lagi, ya.';

  @override
  String get accountFieldSignIn => 'Masuk dengan';

  @override
  String get accountFieldSignInGoogleCaption =>
      'Keamanan akun ini dijaga oleh akun Google-mu.';

  @override
  String get quizMealScoreEyebrow => 'SKOR HARI INI';
}
