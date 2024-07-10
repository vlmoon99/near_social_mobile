import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';

class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user});

  final FullUserInfo user;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0).r,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0).r,
        onTap: () {
          HapticFeedback.lightImpact();
          Modular.to.pushNamed(
            ".${Routes.home.userPage}?accountId=${user.generalAccountInfo.accountId}",
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15).r,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                child: Row(
                  children: [
                    Container(
                      width: 40.h,
                      height: 40.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10).r,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NearNetworkImage(
                        imageUrl: user.generalAccountInfo.profileImageLink,
                        errorPlaceholder: Image.asset(
                          NearAssets.standartAvatar,
                          fit: BoxFit.cover,
                        ),
                        placeholder: Image.asset(
                          NearAssets.standartAvatar,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.h),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (user.generalAccountInfo.name != "")
                            Text(
                              user.generalAccountInfo.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            "@${user.generalAccountInfo.accountId}",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: user.generalAccountInfo.name != ""
                                ? const TextStyle(
                                    color: NEARColors.gray,
                                    fontSize: 13,
                                  )
                                : const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
