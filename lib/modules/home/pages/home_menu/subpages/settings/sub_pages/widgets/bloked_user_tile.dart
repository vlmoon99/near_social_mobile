import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/home/vms/users/models/user_list_state.dart';
import 'package:near_social_mobile/modules/home/vms/users/user_list_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/shared_widgets/near_network_image.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class BlockedUserTile extends StatefulWidget {
  const BlockedUserTile({
    super.key,
    required this.accountIdOfBlockedUser,
    required this.actionToDoTile,
    required this.actionToDoOnPressed,
  });

  final String accountIdOfBlockedUser;
  final String actionToDoTile;
  final Function() actionToDoOnPressed;

  @override
  State<BlockedUserTile> createState() => _BlockedUserTileState();
}

class _BlockedUserTileState extends State<BlockedUserTile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Modular.get<UserListController>().loadAndAddGeneralAccountInfoIfNotExists(
          accountId: widget.accountIdOfBlockedUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final UserListController userListController =
        Modular.get<UserListController>();
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0).r,
      ),
      child: StreamBuilder(
        stream: userListController.stream,
        builder: (context, snapshot) {
          return InkWell(
            borderRadius: BorderRadius.circular(16.0).r,
            onTap: () {
              if (userListController.state.activeUsers
                  .containsKey(userListController.state)) {
                HapticFeedback.lightImpact();
                Modular.to.pushNamed(
                  ".${Routes.home.userPage}?accountId=${widget.accountIdOfBlockedUser}",
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(15).r,
              child: SizedBox(
                height: 40.h,
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: Durations.short4,
                  child: (userListController.state.activeUsers
                              .containsKey(widget.accountIdOfBlockedUser) ||
                          userListController.state.cachedUsers
                              .containsKey(widget.accountIdOfBlockedUser))
                      ? Builder(builder: (context) {
                          final FullUserInfo user = userListController.state
                              .getUserByAccountId(
                                  accountId: widget.accountIdOfBlockedUser);
                          return Row(
                            children: [
                              Container(
                                width: 40.h,
                                height: 40.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10).r,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: NearNetworkImage(
                                  imageUrl:
                                      user.generalAccountInfo.profileImageLink,
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
                                        maxLines: 1,
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
                                              color: NEARColors.grey,
                                              fontSize: 13,
                                            )
                                          : const TextStyle(
                                              fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10.h),
                              FittedBox(
                                child: CustomButton(
                                  primary: true,
                                  onPressed: widget.actionToDoOnPressed,
                                  child: Text(
                                    widget.actionToDoTile,
                                  ),
                                ),
                              ),
                            ],
                          );
                        })
                      : const Center(
                          child: SpinnerLoadingIndicator(),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
