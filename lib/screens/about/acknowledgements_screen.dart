import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';

class AcknowledgementsScreen extends ConsumerWidget {
  const AcknowledgementsScreen({super.key});

  static const String _titleNe = 'पारिवारिक विवरण लेखन कार्य';
  static const String _titleEn = 'Family Documentation Project - Acknowledgements';

  static const String _noteNe =
      'धर्मानन्द भण्डारीको पारिवारिक विवरण लेखन कार्यमा सहयोग गर्ने महानुभावहरूप्रति कृतज्ञता\n\n'
      'वासिषठ भण्डारी समाजको पहलमा धर्मानन्द भण्डारीको पारिवारिक इतिहास तथा वंशावलीलाई व्यवस्थित रूपमा संकलन गरी लेखन गर्ने महत्वपूर्ण कार्य सफलतापूर्वक सम्पन्न भएकोमा सम्पूर्ण समाज अत्यन्त गौरवान्वित भएको छ। आफ्नो वंश, परम्परा, संस्कार र ऐतिहासिक पहिचानलाई सुरक्षित राख्दै भावी पुस्तासम्म पु-याउने उद्देश्यले गरिएको यो कार्य वास्तवमै प्रशंसनीय र दीर्घकालीन महत्वको छ।\n\n'
      'इतिहास, परम्परा र संस्कृतिको संरक्षण गर्नु केवल एक व्यक्तिको प्रयासबाट सम्भव हुँदैन। यसका लागि सामूहिक भावना, सहयोग र समर्पण आवश्यक पर्दछ। यही भावनाका साथ यस पारिवारिक विवरण लेखन कार्यमा धेरै महानुभावहरूले प्रत्यक्ष तथा अप्रत्यक्ष रूपमा सहयोग पु-याउनु भएको छ, जसका कारण यो अभियान सफलतापूर्वक सम्पन्न हुन सकेको हो।\n\n'
      'विशेष गरी यस कार्यमा महत्वपूर्ण सहयोग पु-याउनुहुने कृष्ण (बुद्धिनाथ) भण्डारी, पिताम्बर भण्डारी, लीलानाथ भण्डारी, गंगा भण्डारी, नन्दु भण्डारी तथा दिनेश भण्डारी प्रति वासिषठ भण्डारी समाज हार्दिक आभार तथा सम्मान व्यक्त गर्दछ। उहाँहरूको सक्रिय सहभागिता, समर्पण र सहयोगले यस कार्यलाई पूर्णता दिन महत्वपूर्ण भूमिका निर्वाह गरेको छ।\n\n'
      'त्यसैगरी भौगोलिक दूरीका कारण टाढा रहँदा रहँदै पनि निरन्तर सहयोग, सुझाव र हौसला प्रदान गर्नुहुने खदानन्द भण्डारी र केदार भण्डारी प्रति पनि विशेष धन्यवाद व्यक्त गर्न चाहन्छौं। उहाँहरूको सहयोगले यो अभियानलाई थप ऊर्जा र प्रेरणा प्रदान गरेको छ।\n\n'
      'यस कार्यलाई आधुनिक प्रविधिसँग जोड्दै दस्तावेजलाई व्यवस्थित र सुरक्षित रूपमा राख्न IT तथा Application निर्माण सम्बन्धी महत्वपूर्ण सहयोग प्रदान गर्नुहुने प्रमेश भण्डारी प्रति पनि विशेष कृतज्ञता व्यक्त गर्दछौं। उहाँको प्राविधिक सहयोगले पारिवारिक विवरणलाई डिजिटल रूपमा सुरक्षित राख्ने र भविष्यमा सजिलै प्रयोग गर्न सकिने वातावरण तयार भएको छ।\n\n'
      'यस प्रकार सबै सहयोगी महानुभावहरूको सामूहिक प्रयास, सहयोग र सद्भावका कारण धर्मानन्द भण्डारीको पारिवारिक विवरण लेखन कार्य सफलतापूर्वक सम्पन्न भएको छ। यसले भण्डारी वंशको इतिहास संरक्षण गर्नुका साथै भावी पुस्तालाई आफ्नो मूल, पहिचान र परम्परासँग परिचित गराउने महत्वपूर्ण आधार प्रदान गर्ने विश्वास लिइएको छ।\n\n'
      'अन्त्यमा, यस ऐतिहासिक तथा सांस्कृतिक कार्यमा प्रत्यक्ष वा अप्रत्यक्ष रूपमा सहयोग पु-याउनुहुने केन्द्रिय तथा जिल्ला कार्यसमितिका सम्पूर्ण महानुभावहरू प्रति वासिषठ भण्डारी समाज हार्दिक धन्यवाद तथा सम्मान व्यक्त गर्दछ। भविष्यमा पनि यस्ता महत्वपूर्ण कार्यहरूमा सबैको साथ, सहयोग र सद्भाव निरन्तर प्राप्त हुने अपेक्षा राखिएको छ।';

  static const String _noteEn =
      'The Vasistha Bhandari Society expresses deep gratitude to all those who contributed to the family history documentation project of Dharmananda Bhandari. Under the Society\'s initiative, the systematic collection and documentation of Dharmananda Bhandari\'s family history and genealogy has been successfully completed, and the entire community takes great pride in this achievement. This endeavor, carried out with the noble purpose of preserving the family\'s lineage, traditions, values, and historical identity for future generations, is truly commendable and holds lasting significance.\n\n'
      'Preserving history, tradition, and culture is not something one person can accomplish alone. It requires a collective spirit, cooperation, and dedication. With that spirit in mind, many individuals contributed directly and indirectly to make this documentation project a success.\n\n'
      'The Vasistha Bhandari Society extends its heartfelt gratitude and respect to Krishna (Buddhinath) Bhandari, Pitambar Bhandari, Lilanath Bhandari, Ganga Bhandari, Nandu Bhandari, and Dinesh Bhandari for their invaluable contributions. Their active participation, commitment, and support played a crucial role in bringing this work to completion.\n\n'
      'Special thanks are also due to Khadananda Bhandari and Kedar Bhandari, who despite being far away geographically provided continuous encouragement, suggestions, and moral support throughout the project. Their involvement added energy and motivation to the entire effort.\n\n'
      'Gratitude is also extended to Pramesh Bhandari for his significant technical support in integrating modern technology into the project, developing IT systems and applications to organize and securely preserve the documentation. His technical contribution has created an environment where the family records are digitally preserved and easily accessible for future use.\n\n'
      'Through the collective efforts, cooperation, and goodwill of all these contributors, the family documentation project of Dharmananda Bhandari has been successfully completed. It is believed that this work will not only preserve the history of the Bhandari lineage but also serve as a vital foundation for future generations to connect with their roots, identity, and traditions.\n\n'
      'Finally, the Vasistha Bhandari Society expresses sincere thanks and respect to all members of the central and district committees who supported this historic and cultural undertaking in any capacity. It is hoped that the same spirit of cooperation, support, and goodwill will continue in such meaningful endeavors in the future.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = ref.watch(currentLanguageProvider);
    final isNepali = langCode == 'ne';

    return Scaffold(
      appBar: AppBar(
        title: Text(isNepali ? _titleNe : _titleEn),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5E7CE), Color(0xFFFDF8EE)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -36,
              right: -28,
              child: _DecorDot(size: 120, color: Color(0x1FA66A2C)),
            ),
            Positioned(
              top: 120,
              left: -34,
              child: _DecorDot(size: 92, color: Color(0x1F8E5E2E)),
            ),
            Positioned(
              bottom: -40,
              right: 10,
              child: _DecorDot(size: 130, color: Color(0x1FA66A2C)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFD5B381),
                      width: 1.4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEED9B5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.workspace_premium,
                              color: Color(0xFF7A552B),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isNepali ? _titleNe : _titleEn,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF4B2E1B),
                                    height: 1.25,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 3,
                        width: 84,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB07A3A),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SelectableText(
                        isNepali ? _noteNe : _noteEn,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.65,
                              color: const Color(0xFF3F2A1A),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorDot extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorDot({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
