import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutterchain/flutterchain_lib/models/chains/near/mintbase_category_nft.dart';
import 'package:image_picker/image_picker.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/pages/home_menu/subpages/mint_manager/widgets/mint_nft_dialog.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';

class MintNftPage extends StatefulWidget {
  const MintNftPage({super.key, required this.nftCollectionContract});

  final String nftCollectionContract;

  @override
  State<MintNftPage> createState() => _MintNftPageState();
}

class _MintNftPageState extends State<MintNftPage> {
  final formKey = GlobalKey<FormState>();
  Uint8List? nftMediaData;

  final TextEditingController _nftNameController = TextEditingController();
  final TextEditingController _nftDescriptionController =
      TextEditingController();
  final TextEditingController _amountToMintController = TextEditingController()
    ..text = "1";
  final TextEditingController _nftTagsController = TextEditingController();
  CategoryNFT category = CategoryNFT.art;

  final List<TextEditingController> _accountIdRoyaltiesControllers = [];
  final List<TextEditingController> _percentRoyaltiesControllers = [];
  final List<TextEditingController> _accountIdOwnersControllers = [];
  final List<TextEditingController> _percentOwnersControllers = [];

  Future<void> pickImage() async {
    final pickedImageFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImageFile == null) {
      return;
    }
    pickedImageFile.readAsBytes().then(
      (imageData) {
        setState(() {
          nftMediaData = imageData;
        });
      },
    );
  }

  Map<String, int> convertToSplit({
    required List<TextEditingController> percentControllers,
    required List<TextEditingController> accountIdControllers,
  }) {
    Map<String, int> data = {};
    for (int row = 0; row < percentControllers.length; row++) {
      String accountId = accountIdControllers[row].text;
      int percent = int.tryParse(percentControllers[row].text) ?? 0;
      data[accountId] = percent;
    }
    return data;
  }

  @override
  void dispose() {
    _nftNameController.dispose();
    _nftDescriptionController.dispose();
    _amountToMintController.dispose();
    _nftTagsController.dispose();
    for (var controller in _accountIdRoyaltiesControllers) {
      controller.dispose();
    }
    for (var controller in _percentRoyaltiesControllers) {
      controller.dispose();
    }
    for (var controller in _accountIdOwnersControllers) {
      controller.dispose();
    }
    for (var controller in _percentOwnersControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mint NFT",
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
      ),
      body: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.always,
        child: ListView(
          children: [
            GestureDetector(
              onTap: () {
                if (nftMediaData != null) {
                  pickImage();
                }
              },
              child: Container(
                height: 0.4.sh,
                width: double.infinity,
                color: Colors.black.withOpacity(.1),
                child: nftMediaData == null
                    ? Center(
                        child: SizedBox(
                          width: 160.h,
                          child: CustomButton(
                            onPressed: () async {
                              pickImage();
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.add),
                                SizedBox(width: 10.h),
                                const Text("Add Image"),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Image.memory(
                        nftMediaData!,
                        fit: BoxFit.scaleDown,
                      ),
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16).r,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10).r,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10).r,
                    ),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 15),
                      controller: _nftNameController,
                      decoration: const InputDecoration.collapsed(
                        hintText: "Title",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter title';
                        }
                        return null;
                      },
                      onTapOutside: (event) {
                        if (WidgetsBinding.instance.window.viewInsets.bottom !=
                            0) {
                          return;
                        }
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: const EdgeInsets.all(10).r,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10).r,
                    ),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 15),
                      controller: _nftDescriptionController,
                      decoration: const InputDecoration.collapsed(
                        hintText: "Description",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                      onTapOutside: (event) {
                        if (WidgetsBinding.instance.window.viewInsets.bottom !=
                            0) {
                          return;
                        }
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: const EdgeInsets.all(10).r,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10).r,
                    ),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 15),
                      controller: _amountToMintController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration.collapsed(
                        hintText: "Amount to mint",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount to mint';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (int.parse(value) <= 0) {
                          return 'Please enter a number greater than 0';
                        }
                        return null;
                      },
                      onTapOutside: (event) {
                        if (WidgetsBinding.instance.window.viewInsets.bottom !=
                            0) {
                          return;
                        }
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      const Text("Category: "),
                      SizedBox(width: 10.h),
                      DropdownButton<CategoryNFT>(
                        alignment: Alignment.center,
                        value: category,
                        onChanged: (newCategory) {
                          setState(() {
                            category = newCategory!;
                          });
                        },
                        items: CategoryNFT.values
                            .map(
                              (category) => DropdownMenuItem<CategoryNFT>(
                                alignment: Alignment.center,
                                value: category,
                                child: Text(
                                  category.name.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      )
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          "Additional params",
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "(optional)",
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: NEARColors.grey,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: const EdgeInsets.all(10).r,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10).r,
                    ),
                    child: TextField(
                      style: const TextStyle(fontSize: 15),
                      controller: _nftTagsController,
                      decoration: const InputDecoration.collapsed(
                        hintText: "Tags (separated by comma)",
                      ),
                      onTapOutside: (event) {
                        if (WidgetsBinding.instance.window.viewInsets.bottom !=
                            0) {
                          return;
                        }
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),

                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Forever Royalties",
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              "Maximum royalties percentage is 50%",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: NEARColors.grey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (getRoyaltiesFields.isEmpty)
                        CustomButton(
                          child: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _accountIdRoyaltiesControllers
                                  .add(TextEditingController());
                              _percentRoyaltiesControllers
                                  .add(TextEditingController());
                            });
                          },
                        ),
                    ],
                  ),
                  // SizedBox(height: 10.h),
                  ...getRoyaltiesFields,
                  if (getRoyaltiesFields.isNotEmpty)
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10).r,
                        child: SizedBox(
                          width: 100.h,
                          child: CustomButton(
                            child: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _accountIdRoyaltiesControllers
                                    .add(TextEditingController());
                                _percentRoyaltiesControllers
                                    .add(TextEditingController());
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Split Revenue",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      if (getSplitRevenueFields.isEmpty)
                        CustomButton(
                          child: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _accountIdOwnersControllers
                                  .add(TextEditingController());
                              _percentOwnersControllers
                                  .add(TextEditingController());
                            });
                          },
                        ),
                    ],
                  ),
                  ...getSplitRevenueFields,
                  if (getSplitRevenueFields.isNotEmpty)
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10).r,
                        child: SizedBox(
                          width: 100.h,
                          child: CustomButton(
                            child: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _accountIdOwnersControllers
                                    .add(TextEditingController());
                                _percentOwnersControllers
                                    .add(TextEditingController());
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 30).r,
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        primary: true,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          if (nftMediaData == null) {
                            throw AppExceptions(
                              messageForUser: "Please select an image",
                              messageForDev: "nftMediaData is null",
                            );
                          }

                          Map<String, int>? splitOwners;
                          Map<String, int>? splitBetween;

                          if (_accountIdOwnersControllers.isNotEmpty) {
                            splitOwners = convertToSplit(
                              accountIdControllers: _accountIdOwnersControllers,
                              percentControllers: _percentOwnersControllers,
                            );
                            if (splitOwners.values.reduce((a, b) => a + b) >
                                100) {
                              throw AppExceptions(
                                messageForUser:
                                    "Split between owners can't be more than 100%",
                                messageForDev: "splitOwners $splitOwners",
                              );
                            }
                          }

                          if (_accountIdRoyaltiesControllers.isNotEmpty) {
                            splitBetween = convertToSplit(
                              accountIdControllers:
                                  _accountIdRoyaltiesControllers,
                              percentControllers: _percentRoyaltiesControllers,
                            );
                            if (splitBetween.values.reduce((a, b) => a + b) >
                                50) {
                              throw AppExceptions(
                                messageForUser:
                                    "Split between royalties can't be more than 50%",
                                messageForDev: "splitBetween $splitBetween",
                              );
                            }
                          }
                          List<String>? tagsList;
                          if (_nftTagsController.text.isNotEmpty) {
                            tagsList = _nftTagsController.text
                                .split(",")
                                .map((tag) => tag.trim())
                                .toList();
                          }

                          showDialog(
                            context: context,
                            builder: (context) {
                              return MintNFTDialog(
                                nftCollectionContract:
                                    widget.nftCollectionContract,
                                title: _nftNameController.text,
                                description: _nftDescriptionController.text,
                                mediaBytes: nftMediaData!,
                                tagsList: tagsList,
                                splitOwners: splitOwners,
                                splitBetween: splitBetween,
                                category: category,
                                numToMint:
                                    int.parse(_amountToMintController.text),
                              );
                            },
                          );
                          FocusScope.of(context).requestFocus(FocusNode());
                        },
                        child: const Text("Mint"),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> get getRoyaltiesFields {
    List<Widget> list = [];
    for (var i = 0; i < _accountIdRoyaltiesControllers.length; i++) {
      list.add(Container(
        padding: const EdgeInsets.all(10).r,
        margin: const EdgeInsets.only(top: 10).r,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12).r,
          border: Border.all(color: Colors.black12, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10).r,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10).r,
                    ),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 15),
                      controller: _accountIdRoyaltiesControllers[i],
                      decoration: const InputDecoration.collapsed(
                        hintText: "AccountId",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter accountId';
                        }
                        return null;
                      },
                      onTapOutside: (event) {
                        if (WidgetsBinding.instance.window.viewInsets.bottom !=
                            0) {
                          return;
                        }
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Container(
                    padding: const EdgeInsets.all(10).r,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10).r,
                    ),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 15),
                      keyboardType: TextInputType.number,
                      controller: _percentRoyaltiesControllers[i],
                      decoration: const InputDecoration.collapsed(
                        hintText: "Percent",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter percent';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Percent must be a number';
                        }
                        return null;
                      },
                      onTapOutside: (event) {
                        if (WidgetsBinding.instance.window.viewInsets.bottom !=
                            0) {
                          return;
                        }
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _accountIdRoyaltiesControllers.removeAt(i);
                  _percentRoyaltiesControllers.removeAt(i);
                });
              },
              icon: const Icon(
                Icons.remove,
                color: NEARColors.black,
              ),
            ),
          ],
        ),
      ));
    }
    return list;
  }

  List<Widget> get getSplitRevenueFields {
    List<Widget> list = [];
    for (var i = 0; i < _accountIdOwnersControllers.length; i++) {
      list.add(Container(
        padding: const EdgeInsets.all(10).r,
        margin: const EdgeInsets.only(top: 10).r,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12).r,
          border: Border.all(color: Colors.black12, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10).r,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10).r,
                    ),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 15),
                      controller: _accountIdOwnersControllers[i],
                      decoration: const InputDecoration.collapsed(
                        hintText: "AccountId",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter accountId';
                        }
                        return null;
                      },
                      onTapOutside: (event) {
                        if (WidgetsBinding.instance.window.viewInsets.bottom !=
                            0) {
                          return;
                        }
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Container(
                    padding: const EdgeInsets.all(10).r,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10).r,
                    ),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 15),
                      keyboardType: TextInputType.number,
                      controller: _percentOwnersControllers[i],
                      decoration: const InputDecoration.collapsed(
                        hintText: "Percent",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter percent';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Percent must be a number';
                        }
                        return null;
                      },
                      onTapOutside: (event) {
                        if (WidgetsBinding.instance.window.viewInsets.bottom !=
                            0) {
                          return;
                        }
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _accountIdOwnersControllers.removeAt(i);
                  _percentOwnersControllers.removeAt(i);
                });
              },
              icon: const Icon(
                Icons.remove,
                color: NEARColors.black,
              ),
            ),
          ],
        ),
      ));
    }
    return list;
  }
}
