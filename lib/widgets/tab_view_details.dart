import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import './custom_text.dart';
import '../constants.dart';

class TabViewDetails extends StatelessWidget {
  final String? titleText;
  final List<String>? listText;
  final String? description;

  const TabViewDetails({
    super.key,
    this.titleText,
    this.listText,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    if (description != null) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Html(
            data: description!,
            style: {
              "body": Style(
                fontSize: FontSize(15.0),
                color: kTextColor,
              ),
              "li": Style(
                margin: const Margins.only(bottom: 8),
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
                    CustomText(
                      text: listText![index],
                      colors: kGreyLightColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
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
