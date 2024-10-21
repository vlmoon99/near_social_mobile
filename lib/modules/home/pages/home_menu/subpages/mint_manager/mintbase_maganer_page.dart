import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/vm/mintbase_controller.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/widgets/home_menu_list_tile.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/shared_widgets/spinner_loading_indicator.dart';

class MintbaseManagerPage extends StatefulWidget {
  const MintbaseManagerPage({super.key});

  @override
  State<MintbaseManagerPage> createState() => _MintbaseManagerPageState();
}

class _MintbaseManagerPageState extends State<MintbaseManagerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final MintbaseController mintbaseController =
          Modular.get<MintbaseController>();
      final AuthController authController = Modular.get<AuthController>();
      if (mintbaseController.state.loadStatus ==
          MintbaseAccountStateLoadStatus.init) {
        await mintbaseController.loadAccountInfo(
          authController.state.accountId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final MintbaseController mintbaseController =
        Modular.get<MintbaseController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mintbase Manager",
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
      ),
      body: StreamBuilder(
        stream: mintbaseController.stream,
        builder: (context, snapshot) {
          if (mintbaseController.state.loadStatus !=
              MintbaseAccountStateLoadStatus.loaded) {
            return const Center(
              child: SpinnerLoadingIndicator(),
            );
          }
          return SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20).r,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 15.h),
                  HomeMenuListTile(
                    tile: const Icon(Icons.dashboard_customize_sharp),
                    title: "Collections you own",
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Modular.to
                          .pushNamed(".${Routes.home.mintbaseCollectionsPage}");
                    },
                  ),
                  SizedBox(height: 15.h),
                  HomeMenuListTile(
                    tile: const Icon(Icons.collections_rounded),
                    title: "All NFTs",
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Modular.to
                          .pushNamed(".${Routes.home.allMintbaseNftsPage}");
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
