// ================================================================
// 📖 data_doa.dart — Kumpulan Doa Sehari-hari (Sumber Hadis)
// ================================================================
// Fungsi utama: getDoaList(category)
// Mengembalikan List<Map<String, String>> sesuai kategori
// ================================================================

List<Map<String, String>> getDoaList(String category) {
  switch (category) {
    case "Makanan & Minuman":
      return [
        {
          'image': 'assets/images/ic_doa_makanan_minuman.png',
          'title': 'Do’a Sebelum Makan',
          'arabicText': 'بِسْمِ اللَّهِ',
          'translation': 'Dengan menyebut nama Allah',
          'reference': 'Hadist Riwayat Abu Dawud dan At-Tirmidzi',
        },
        {
          'image': 'assets/images/ic_doa_makanan_minuman.png',
          'title': 'Do’a Setelah Makan',
          'arabicText':
              'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
          'translation':
              'Segala puji bagi Allah yang telah memberiku makanan ini dan rezeki ini dengan tanpa daya dan kekuatan dariku',
          'reference': 'Hadist Riwayat Abu Dawud, At-Tirmidzi, dan Ibnu Majah',
        },
        {
          'image': 'assets/images/ic_doa_makanan_minuman.png',
          'title': 'Do’a Orang Yang Memberi Minum',
          'arabicText':
              'اللَّهُمَّ أَطْعِمْ مَنْ أَطْعَمَنِي، وَاسْقِ مَنْ سَقَانِي',
          'translation':
              'Ya Allah, berilah makan orang yang memberi makan kepadaku dan berilah minum orang yang memberi minum kepadaku',
          'reference': 'HR. Muslim',
        },
        {
          'image': 'assets/images/ic_doa_makanan_minuman.png',
          'title': 'Do’a Berbuka Di Rumah Orang Lain',
          'arabicText':
              'أَفْطَرَ عِنْدَكُمُ الصَّائِمُونَ، وَأَكَلَ طَعَامَكُمُ الأَبْرَارُ، وَصَلَّتْ عَلَيْكُمُ الْمَلاَئِكَةُ',
          'translation':
              'Semoga orang-orang yang berpuasa berbuka di tempat kalian, dan semoga orang-orang baik makan makanan kalian, dan semoga para malaikat mendoakan kalian',
          'reference': 'HR. Abu Dawud',
        },
        {
          'image': 'assets/images/ic_doa_makanan_minuman.png',
          'title': 'Do’a Berbuka Puasa',
          'arabicText':
              'ذَهَبَ الظَّمَأُ، وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ',
          'translation':
              'Telah hilang dahaga, urat-urat telah basah, dan telah ditetapkan pahala insya Allah',
          'reference': 'HR. Abu Dawud',
        },
      ];
    case "Pagi & Malam":
      return [
        {
          'image': 'assets/images/ic_doa_pagi_malam.png',
          'title': 'Do’a Sebelum Tidur',
          'arabicText': 'اللَّهُمَّ بِاسْمِكَ أَمُوتُ وَأَحْيَا',
          'translation': 'Ya Allah, dengan namaMu aku mati dan aku hidup.',
          'reference': 'Hadist Riwayat Bukhori',
        },
        {
          'image': 'assets/images/ic_doa_pagi_malam.png',
          'title': 'Do’a Bangun Tdiur',
          'arabicText':
              'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
          'translation':
              'Segala puji bagi Allah yang menghidupkanku dan mematikanku dan kepadaNya lah kita dikembalikan.',
          'reference': 'Hadist Riwayat Bukhori',
        },
        {
          'image': 'assets/images/ic_doa_pagi_malam.png',
          'title': 'Doa Apabila Ada Yang Menakutkan Dalam Tidur',
          'arabicText':
              'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ غَضَبِهِ وَعِقَابِهِ، وَشَرِّ عِبَادِهِ، وَمِنْ هَمَزَاتِ الشَّيَاطِينِ وَأَنْ يَحْضُرُونِ',
          'translation':
              'Aku berlindung dengan kalimat Allah yang sempurna dari kemarahan, siksaan dan kejahatan hamba-hamba-Nya dan dari godaan setan serta jangan sampai setan mendatangiku',
          'reference': 'Hadist Riwayat Abu Dawud dan Shohih At-Tirmidzi',
        },
      ];
    case "Rumah":
      return [
        {
          'image': 'assets/images/ic_doa_rumah.png',
          'title': 'Do’a Berpakaian',
          'arabicText':
              'لْحَمْدُ لِلّهِ الَّذِي كَسَانِي هَذَا (الثَّوْبَ) وَرَزَقَنِيهِ مِنْ غَـيـْرِ حَوْلٍ مِنِّي وَلَا قُـوَّةٍ',
          'translation':
              'Segala puji bagi Allah Yang telah memberikan pakaian ini kepadaku sebagai rezeki dari-pada-Nya tanpa daya dan kekuatan dari-ku.',
          'reference':
              'Hadist Riwayat Bukhari, Muslim, Ibnu Majah, dan At-Tirmidzi',
        },
        {
          'image': 'assets/images/ic_doa_rumah.png',
          'title': 'Do’a Masuk WC',
          'arabicText':
              'بِسْمِ اللَّهِ. اللَّهُـمَّ إِنِّي أَعُـوذُ بِـكَ مِـنَ الْخُـبْثِ وَالْخَبَائِثِ',
          'translation':
              'Dengan nama Allah. Ya Allah, sesungguhnya aku berlindung kepada-Mu dari godaan setan laki-laki dan perempuan.',
          'reference': 'Hadist Riwayat Bukhari dan Fathul Bari',
        },
        {
          'image': 'assets/images/ic_doa_rumah.png',
          'title': 'Do’a Keluar WC',
          'arabicText': 'غُفْرَانَكَ',
          'translation': 'Aku minta ampun kepada-Mu.',
          'reference':
              'Hadist Riwayat Abu Dawud, Ibnu Majah, At-Tirmidzi, An-Nasa\'i, Al-Qayyim\'s Zadul-Ma\'ad',
        },
        {
          'image': 'assets/images/ic_doa_rumah.png',
          'title': 'Do’a Masuk Rumah',
          'arabicText':
              'بِسْـمِ اللّهِ وَلَجْنـَا، وَبِسْـمِ اللّهِ خَـرَجْنـَا، وَعَلَـى رَبِّنـَا تَوَكّلْـنَا',
          'translation':
              'Dengan nama Allah, kami masuk (ke rumah), dengan nama Allah, kami keluar (darinya) dan kepada Tuhan kami, kami bertawakkal”. Kemudian mengucapkan salam kepada keluarga-nya.',
          'reference': 'Hadist Riwayat Abu Dawud',
        },
        {
          'image': 'assets/images/ic_doa_rumah.png',
          'title': 'Do’a Keluar Rumah',
          'arabicText':
              'بِسْمِ اللَّهِ تَوَكَّلْـتُ عَلَى اللَّهِ، وَلاَ حَوْلَ وَلاَ قُـوَّةَ إِلاَّ بِاللَّهِ',
          'translation':
              'Dengan nama Allah (aku keluar). Aku bertawakkal kepada-Nya, dan tiada daya dan kekuatan kecuali karena pertolongan Allah.',
          'reference':
              'Hadist Riwayat Abu Dawud, At-Tirmidzi, Al-Albani, dan Shohih At-Tirmidzi',
        },
      ];
    case "Perjalanan":
      return [
        {
          'image': 'assets/images/ic_doa_perjalanan.png',
          'title': 'Do’a Naik Kendaraan',
          'arabicText':
              'بِسْمِ اللَّهِ وَالْحَمْدُ لِلَّهِ، سُبْحَانَ الَّذِي سَخَّرَ لَناَ هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ، وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ، الْحَمْدُ لِلَّهِ، الْحَمْدُ لِلَّهِ، الْحَمْدُ لِلَّهِ، اللَّهُ أكْبَرُ، اللَّهُ أكْبَرُ، اللَّهُ أكْبَرُ، سُبْحَانَكَ اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي فَاغْفِرْ لِي، فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلَاَّ أَنْتَ',
          'translation':
              'Dengan nama Allah, segala puji bagi Allah, Maha Suci Tuhan yang menundukkan kendaraan ini untuk kami, padahal kami sebelumnya tidak mampu menguasainya. Dan sesungguhnya kami akan kembali kepada Tuhan kami (di hari kiamat). Segala puji bagi Allah (3x), Maha Suci Engkau, ya Allah! Sesungguhnya aku menganiaya diriku, maka ampunilah aku. Sesungguhnya tidak ada yang dapat mengampuni dosa-dosa kecuali Engkau.',
          'reference': 'Hadist Riwayat Abu Dawud dan At-Tirmidzi',
        },
        {
          'image': 'assets/images/ic_doa_perjalanan.png',
          'title': 'Doa Masuk Pasar',
          'arabicText':
              'لَا إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لَا شَرِيكَ لهُ، لَهُ الْمُلْكُ وَلهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ وَهُوَ حَيٌّ لَا يَمُوتُ، بِيَدِهِ الْخَيْرُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
          'translation':
              'Tidak ada Tuhan yang berhak disembah selain Allah, Yang Maha Esa, tiada sekutu bagi-Nya. Bagi-Nya kerajaan, bagi-Nya segala pujian. Dia-lah Yang Menghidupkan dan Yang Mematikan. Dia-lah Yang Hidup, tidak akan mati. Di tangan-Nya kebaikan. Dia-lah Yang Maha Kuasa atas segala sesuatu.',
          'reference': 'Hadist Riwayat At-Tirmidzi dan Al-Hakim',
        },
        {
          'image': 'assets/images/ic_doa_perjalanan.png',
          'title': 'Doa Musafir Kepada Orang Yang Di Tingggalkan',
          'arabicText':
              'أَسْتَوْدِعُكُمُ اللَّهَ الَّذِي لَا تَضِيعُ وَدَائِعُهُ',
          'translation':
              'Aku menitipkan kalian kepada Allah yang tidak akan hilang titipan-Nya.',
          'reference': 'Hadist Riwayat Ahmad dan Ibnu Majah',
        },
        {
          'image': 'assets/images/ic_doa_perjalanan.png',
          'title': 'Doa Orang Muqim Kepada Musafir',
          'arabicText':
              'أَسْتَوْدِعُ اللَّهَ دِينَكَ، وَأَمَانَتَكَ، وَخَوَاتِيمَ عَمَلِكَ',
          'translation': 'Aku menitipkan agama, amanah dan penutup amalmu.',
          'reference': 'Hadist Riwayat Ahmad dan At-Tirmidzi',
        },
      ];
    case "Sholat":
      return [
        {
          'image': 'assets/images/ic_doa_sholat.png',
          'title': 'Do’a Sebelum Wudhu',
          'arabicText': 'بِسْمِ اللَّه',
          'translation': 'Dengan nama Allah (aku berwudhu).',
          'reference':
              'Hadist Riwayat Abu Dawud, Ibnu Majah, dan Irwa\'ul-Ghain',
        },
        {
          'image': 'assets/images/ic_doa_sholat.png',
          'title': 'Do’a Setelah Wudhu',
          'arabicText':
              'أَشْهَدُ أَنْ لَا إِلَـهَ إِلاَّ اللّهُ وَحْدَهُ لَا شَريـكَ لَـهُ وَأَشْهَدُ أَنَّ مُحَمَّـداً عَبْـدُهُ وَرَسُـولُـهُ, اَللَّهُـمَّ اجْعَلْنِـي مِنَ التَّـوَّابِينَ وَاجْعَـلْنِي مِنَ الْمُتَطَهِّـرِينَ',
          'translation':
              'Aku bersaksi, bahwa tiada Tuhan yang haq kecuali Allah, Yang Maha Esa dan tiada sekutu bagi-Nya. Aku bersaksi, bahwa Muhammad adalah hamba dan utusan-Nya, Ya Allah, jadikanlah aku termasuk orang-orang yang bertaubat dan jadikanlah aku termasuk orang-orang (yang senang) bersuci.',
          'reference':
              'Hadist Riwayat Muslim, At-Tirmizi, Al-Albani, dan Shahih At-Tirmizi',
        },
        {
          'image': 'assets/images/ic_doa_sholat.png',
          'title': 'Doa Masuk Masjid',
          'arabicText':
              'أَعوذُ بِاللّهِ العَظِيـمِ، وَبِوَجْهِـهِ الكَرِيـمِ وَسُلْطـَانِه القَدِيـمِ، مِنَ الشَّيْـطَانِ الرَّجِـيمِ، بِسْـمِ اللّهِ وَالصَّلَاةُ وَالسَّلامُ عَلَى رَسُولِ اللّهِ، اَللَّهُـمَّ افْتَـحْ لِي أَبْوَابَ رَحْمَتـِكَ',
          'translation':
              'Aku berlindung kepada Allah Yang Maha Agung, dengan wajah-Nya Yang Mulia dan kekuasaan-Nya yang abadi, dari setan yang terkutuk.  Dengan nama Allah dan semoga shalawat   dan salam tercurahkan kepada Rasulullah   Ya Allah, bukalah pintu-pintu rahmat-Mu untukku.',
          'reference':
              'Hadist Riwayat Abu Dawud, Jami\' As-Saghir, Ibn As-Sunni, Abu Dawud, Shahihul Jami\', Muslim, dan Ibnu Majah',
        },
        {
          'image': 'assets/images/ic_doa_sholat.png',
          'title': 'Doa keluar masjid',
          'arabicText':
              'بِسْمِ اللّهِ وَالصَّلاَةُ وَالسَّلاَمُ عَلَى رَسُولِ اللّهِ، اَللَّهُـمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْـلِكَ، اَللَّهُـمَّ اعْصِمْنِـي مِنَ الشَّيْـطَانِ الرَّجِـيمِ',
          'translation':
              'Dengan nama Allah, semoga shalawat dan salam terlimpahkan kepada Rasulullah. Ya Allah, sesungguhnya aku minta kepada-Mu dari karunia-Mu. Ya Allah, peliharalah aku dari godaan setan yang terkutuk.',
          'reference':
              'Hadist Riwayat Abu Dawud, Sahih Al-Jami\', Muslim, Shohih Ibnu Majah',
        },
      ];
    case "Etika Baik":
      return [
        {
          'image': 'assets/images/ic_doa_etika_baik.png',
          'title': 'Do’a Ketika Bersin',
          'arabicText':
              '(3)الْحَمْدُ للَّهِ(1)يَرْحَمُكَاللَّهُ(2)يَهْدِيكُمُ اللَّهُ وَيُصْلِحُ بَالَكُم',
          'translation':
              'Rasulullah bersabda: “Apabila seseorang di antara kamu bersin, hendaklah mengucapkan: الْحَمْدُ لِلَّهِ Segala puji bagi Allah, Lantas saudara atau temannya mengucapkan: يَرْحَمُكَ اللهُ Semoga Allah memberi rahmat kepada-Mu, Bila teman atau saudaranya mengucapkan demikian, bacalah: يَهْدِيْكُمُ اللهُ وَيُصْلِحُ بَالَكُمْ Semoga Allah memberi petunjuk kepadamu dan memperbaiki keadaanmu.',
          'reference': 'Hadist Riwayat Bukhari',
        },
        {
          'image': 'assets/images/ic_doa_etika_baik.png',
          'title': 'Do’a Ketika Marah',
          'arabicText': 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجيـمِ',
          'translation':
              'Aku berlindung kepada Allah dari godaan setan yang terkutuk.',
          'reference': 'Hadist Riwayat Bukhari dan Muslim',
        },
        {
          'image': 'assets/images/ic_doa_etika_baik.png',
          'title': 'Doa Dalam Majelis',
          'arabicText':
              'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الْغَفُورُ',
          'translation':
              'Wahai Tuhanku! Ampunilah aku dan terimalah taubatku, sesungguhnya Engkau Maha Menerima taubat lagi Maha Pengampun (di baca seratus kali sebelum berdiri dari majelis).',
          'reference': 'Hadist Riwayat Ibnu Majah, dan Sahih At-Tirmizi',
        },
        {
          'image': 'assets/images/ic_doa_etika_baik.png',
          'title': 'Doa Untuk Orang Yang Berbuat Kebaikan Kepadamu',
          'arabicText': 'جَزَاكَ اللَّهُ خَيْراً',
          'translation': 'Semoga Allah membalasmu dengan kebaikan',
          'reference': 'Hadist Riwayat At-Tirmizi',
        },
      ];
    default:
      return [];
  }
}
