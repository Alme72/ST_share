// ignore: unused_import
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
// ignore: unused_import
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:test_project/repository/contents_repository.dart';

import 'detail.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final oCcy = NumberFormat(
    "#,###",
    "ko_KR",
  );
  String calcStringToWon(String priceString) {
    return "${oCcy.format(int.parse(priceString))}원";
  }

  late String currentLocation = "sell";
  Future<List<Map<String, dynamic>>> _loadContents() async {
    List<Map<String, dynamic>> responseData =
        await ContentsRepository().loadContentsFromLocation(currentLocation);
    return responseData;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  final TextEditingController _textEditingController = TextEditingController();
  LocationData? _locationData;
  String? _locationText;
  late EdgeInsets safeArea;
  double drawerHeight = 0;

  NLatLng _initialPosition = const NLatLng(0, 0);
  late NaverMapController _controller;

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  // 마커
  final marker1 =
      NMarker(id: '1', position: const NLatLng(37.5666102, 126.9783881));
  //final marker2 = NMarker(id: '2', position: NLatLng(latitude, longitude));

  late List marker = [];
  void makeMaker() {
    for (int i = 0; i < ContentsRepository().datas.length; i++) {
      marker[i] = ContentsRepository().datas[i]["image"];
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _initialPosition = NLatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _goToAddress(String address) async {
    const apiKey = "6AWAOaVaaf3gncmk0OMxo6dGW7xBfco7Yf2ZfPTR";
    final encodedAddress = Uri.encodeComponent(address);
    final apiUrl =
        "https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode?query=$encodedAddress";
    final headers = {
      "X-NCP-APIGW-API-KEY-ID": apiKey,
      "X-NCP-APIGW-API-KEY": apiKey
    };
    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      final jsonResult = jsonDecode(response.body);
      final addresses = jsonResult["addresses"];
      final first = addresses[0];
      final latitude = double.parse(first["y"]);
      final longitude = double.parse(first["x"]);
      _controller.updateCamera(
        NCameraUpdate.fromCameraPosition(
          NCameraPosition(
            target: NLatLng(latitude, longitude),
            zoom: 15,
          ),
        ),
      );
      setState(() {
        _locationData = null;
        _locationText = "($latitude, $longitude)";
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  // 가는길 검색 테스트
  Future<void> _direction15Test(String address) async {
    const apiKey = "6AWAOaVaaf3gncmk0OMxo6dGW7xBfco7Yf2ZfPTR";
    // final encodedAddress = Uri.encodeComponent(address);
    const apiUrl =
        "https://naveropenapi.apigw.ntruss.com/map-direction-15/v1/driving";
    final headers = {
      "X-NCP-APIGW-API-KEY-ID": apiKey,
      "X-NCP-APIGW-API-KEY": apiKey
    };
  }

  Widget _makeDataList(List<Map<String, dynamic>>? datas) {
    int size = datas == null ? 0 : datas.length;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemBuilder: (BuildContext context, int index) {
        if (datas[index]["image"].isEmpty) {
          datas[index]["image"] = [
            "https://png.pngtree.com/png-vector/20190820/ourlarge/pngtree-no-image-vector-illustration-isolated-png-image_1694547.jpg"
          ];
        }
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return DetailContentView(data: datas[index]);
                },
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(10),
                  ),
                  child: Image.network(
                    datas[index]["image"][0],
                    width: 100,
                    height: 100,
                    scale: 0.1,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 100,
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          datas[index]["boardTitle"]!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          datas[index]["location"]!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          calcStringToWon(datas[index]["price"].toString()),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.remove_red_eye_outlined,
                                color: Color.fromARGB(255, 64, 64, 64),
                                size: 17,
                              ),
                              // SvgPicture.asset(
                              //   "assets/svg/heart_off.svg",
                              //   width: 13,
                              //   height: 13,
                              // ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                //datas[index]["like"].toString(),
                                datas[index]["boardHits"].toString(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      itemCount: datas!.length, // 상품 목록의 개수
      separatorBuilder: (BuildContext context, int index) {
        return Container(
          height: 1,
          color: Colors.black.withOpacity(0.4),
        );
      },
    );
  }

  // 리스트 출력을 위한 기능
  Widget _productList() {
    return FutureBuilder(
        future: _loadContents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("데이터를 불러올 수 없습니다."));
          }
          if (snapshot.hasData) {
            return _makeDataList(snapshot.data);
          }
          return const Center(child: Text("해당 거래방식에 대한 데이터가 없습니다."));
        });
  }

  PreferredSizeWidget _appbarWidget() {
    return AppBar(
      title: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
        ),
        child: TextFormField(
          controller: _textEditingController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: "주소를 입력하세요",
            border: InputBorder.none,
          ),
          onFieldSubmitted: (value) {
            _direction15Test(value);
          },
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _bodyWidget() {
    return SnappingSheet(
      grabbingHeight: 40,
      grabbing: Container(
        height: 56,
        color: Colors.white,
        alignment: Alignment.center,
        child: const Text('지도 리스트'),
      ),
      sheetBelow: SnappingSheetContent(
        sizeBehavior: const SheetSizeFill(),
        draggable: true,
        child: Container(
          height: 56,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: _productList(),
        ),
      ),
      snappingPositions: const [
        SnappingPosition.factor(
          positionFactor: 0.0,
          snappingCurve: Curves.easeOutExpo,
          snappingDuration: Duration(seconds: 1),
          grabbingContentOffset: GrabbingContentOffset.top,
        ),
        SnappingPosition.pixels(
          positionPixels: 500,
          snappingCurve: Curves.elasticOut,
          snappingDuration: Duration(milliseconds: 1750),
        ),
        SnappingPosition.factor(
          positionFactor: 1.0,
          snappingCurve: Curves.bounceOut,
          snappingDuration: Duration(seconds: 1),
          grabbingContentOffset: GrabbingContentOffset.bottom,
        ),
      ],
      child: NaverMap(
        onMapReady: (controller) {
          _controller = controller;
          _controller.addOverlay(marker1);
        },
        options: NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: _initialPosition,
            zoom: 16,
          ),
          // minZoom: 10,
          // maxZoom: 16,
          maxTilt: 30,
          symbolScale: 1,
          locationButtonEnable: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    safeArea = MediaQuery.of(context).padding;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    return Scaffold(
      appBar: _appbarWidget(),
      extendBodyBehindAppBar: true,
      body: _initialPosition.latitude == 0 && _initialPosition.longitude == 0
          ? const Center(child: CircularProgressIndicator())
          : _bodyWidget(),
    );
  }
}
