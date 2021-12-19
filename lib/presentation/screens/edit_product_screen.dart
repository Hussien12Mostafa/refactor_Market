// ignore_for_file: prefer_const_constructors, prefer_if_null_operators
import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:market_app/data/models/product.dart';
import 'package:market_app/logic/blocs/products_bloc/product_bloc.dart';
import 'package:market_app/logic/providers/products_provider.dart';
import 'package:market_app/logic/providers/user_provider.dart';
import 'package:path/path.dart' as p;

class EditProductScreen extends StatefulWidget {
  Product product;
  EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _key = GlobalKey<FormState>();
  TextEditingController name = TextEditingController();
  TextEditingController describtion = TextEditingController();
  TextEditingController price = TextEditingController();
  TextEditingController amount = TextEditingController();
  File? imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _validating = false;
  bool _uploading = false;
  Map<String, dynamic> data = {};
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;
  @override
  void initState() {
    name.text = widget.product.name;
    String s = "";
    describtion.text =
        (widget.product.description != null ? widget.product.description : s)!;
    price.text = widget.product.price.toString();
    amount.text = widget.product.amount.toString();
    data["name"] = widget.product.name;

    data["description"] =
        (widget.product.description != null ? widget.product.description : s)!;
    data["price"] = widget.product.price.toString();
    data["amount"] = widget.product.amount.toString();

    data["id"] = widget.product.id;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Product"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Form(
            autovalidateMode: _validating
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            key: _key,
            child: Column(
              children: [
                TextFormField(
                  controller: name,
                  onChanged: (value) {
                    setState(() {
                      data['name'] = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "your product name",
                    label: Text("Title"),
                  ),
                  validator: (value) {
                    if (value!.length < 4) {
                      return "Tile Can noy be less than 4 letters";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: describtion,
                  onChanged: (value) {
                    setState(() {
                      data['description'] = value;
                    });
                  },
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "your product description",
                    label: Text("Description"),
                  ),
                  validator: (value) {
                    /* if (value!.length < 150) {
                      return "Tile Can noy be less than 4 letters";
                    } */
                    return null;
                  },
                ),
                TextFormField(
                  controller: price,
                  onChanged: (value) {
                    setState(() {
                      data['price'] = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "your product price",
                    label: Text("price"),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (double.tryParse(value!) != null)
                      return null;
                    else
                      return "add valid number";
                  },
                ),
                TextFormField(
                  controller: amount,
                  onChanged: (value) {
                    setState(() {
                      data['amount'] = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "your product amount",
                    label: Text("amount"),
                  ),
                  validator: (value) {
                    if (double.tryParse(value!) != null && int.parse(value) > 0)
                      return null;
                    else if (int.parse(value) <= 0)
                      return "add positive number";
                    else
                      return "add valid number";
                  },
                  keyboardType: TextInputType.number,
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                          onPressed: () async {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text("Choose image Source"),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      XFile? photo = await _picker.pickImage(
                                          source: ImageSource.camera);
                                      Navigator.of(context).pop();
                                      try {
                                        setState(() {
                                          imageFile = File(photo!.path);
                                        });
                                      } catch (e) {
                                        print(e);
                                      }
                                    },
                                    child: Text("Camera"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      XFile? photo = await _picker.pickImage(
                                          source: ImageSource.gallery);
                                      Navigator.of(context).pop();
                                      try {
                                        setState(() {
                                          imageFile = File(photo!.path);
                                        });
                                      } catch (e) {
                                        print(e);
                                      }
                                    },
                                    child: Text("Gallery"),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text("Choose Image")),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: imageFile == null
                            ? Center(
                                child: Image.network(widget.product.imageUrl))
                            : Image.file(
                                imageFile!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ],
                  ),
                ),
                _uploading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          if (_key.currentState!.validate() &&
                              (imageFile != null ||
                                  widget.product.imageUrl != null)) {
                            setState(() {
                              _uploading = true;
                            });

                            data['imageUrl'] = imageFile != null
                                ? await uploadFile(imageFile!.path)
                                : widget.product.imageUrl;
                            data['owner_id'] =
                                await RepositoryProvider.of<UserProvider>(
                                        context)
                                    .getUserId();

                            Product p = Product.fromJson(data);
                            
                            BlocProvider.of<ProductsBloc>(context)
                                .add(UpdateProduct(p));
                            setState(() {
                              _uploading = false;
                            });
                            Navigator.of(context).pop();
                          } else if (imageFile == null) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                  title: Text(
                                      "Choose image you can not add product without image"),
                                  actions: [
                                    TextButton(
                                      child: Text("OK"),
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                      },
                                    )
                                  ]),
                            );
                          } else {
                            setState(() {
                              _validating = true;
                            });
                          }
                        },
                        child: Text("Add Product"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> uploadFile(String filePath) async {
    File file = File(filePath);
    String? imageUrl;
    int random = Random().nextInt(1000);
    try {
      await firebase_storage.FirebaseStorage.instance
          .ref('products/${random}${p.extension(file.path)}')
          .putFile(file);
      imageUrl = await firebase_storage.FirebaseStorage.instance
          .ref('products/${random}${p.extension(file.path)}')
          .getDownloadURL();
      print("i end upload");
    } on FirebaseException catch (e) {}

    return imageUrl;
  }
}
