import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import './custom_text.dart';
import '../constants.dart';
import 'package:html_unescape/html_unescape.dart';

class TabViewDetails extends StatelessWidget {
  final String? titleText;
  final List<String>? listText;
  final String? description;
  final bool isDarkMode;

  const TabViewDetails({
    super.key,
    this.titleText,
    this.listText,
    this.description,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = isDarkMode ? Colors.white : const Color(0xFF1F2937);
    Color secondaryTextColor = isDarkMode ? Colors.grey[300]! : const Color(0xFF6B7280);
    
    if (description != null) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Html(
            data: description!,
            style: {
              "body": Style(
                fontSize: FontSize(15.0),
                color: textColor,
              ),
            },
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: CustomText(
                text: titleText,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                colors: textColor,
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: listText?.length ?? 0,
            itemBuilder: (ctx, index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF6366F1) : const Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomText(
                            text: HtmlUnescape().convert(listText![index]),
                            colors: secondaryTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    if((listText!.length - 1) != index)
                    const SizedBox(height: 5),
                    if((listText!.length - 1) != index)
                    Divider(color: kGreyLightColor.withOpacity(0.3)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
