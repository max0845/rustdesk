import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/animated_rotation_widget.dart';
import 'package:flutter_hbb/common/widgets/custom_password.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:flutter_hbb/plugin/ui_manager.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart' as window_size;

import '../widgets/button.dart';

class DesktopHomePage extends StatefulWidget {
  final List<String>? arg;
  const DesktopHomePage({Key? key, this.arg}) : super(key: key);

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

const borderColor = Color(0xFF2F65BA);

class _DesktopHomePageState extends State<DesktopHomePage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final _leftPaneScrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;
  var systemError = '';
  StreamSubscription? _uniLinksSubscription;
  var svcStopped = false.obs;
  var watchIsCanScreenRecording = false;
  var watchIsProcessTrust = false;
  var watchIsInputMonitoring = false;
  var watchIsCanRecordAudio = false;
  Timer? _updateTimer;
  bool isCardClosed = false;

  final RxBool _editHover = false.obs;
  final RxBool _block = false.obs;

  final GlobalKey _childKey = GlobalKey();
  final RxList<String> _arg = <String>[].obs;
  final box = GetStorage();
  final RxString _qrcode = ''.obs;
  final RxString _qrcodeID = ''.obs;
  final RxString _message = ''.obs;
  Timer? _timer;
  final RxString _token = ''.obs;
  final RxString _orgId = ''.obs;
  final RxString _orgNo = ''.obs;
  final RxString _orgName = ''.obs;
  final RxString _clientNo = ''.obs;
  final RxString _location = ''.obs;
  final RxString _id = ''.obs;
  final RxString _pw = ''.obs;
  final RxBool _on1 = false.obs;
  final RxBool _on2 = false.obs;
  final Dio _dio = Dio()
    ..httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true,
    );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const TextStyle style = TextStyle(
      fontSize: 14,
      color: Colors.black,
      decoration: TextDecoration.none,
    );
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.5 - 200,
          left: MediaQuery.of(context).size.width * 0.5 - 100,
          child: Column(
            children: [
              Image.asset('assets/logo.png', width: 200, height: 200),
              Obx(() => _arg.isNotEmpty
                  ? AutoSizeText(
                      _arg[0],
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        decoration: TextDecoration.none,
                      ),
                    )
                  : const SizedBox()),
              Obx(
                () => _qrcode.value.isNotEmpty
                    ? QrImageView(
                        data: _qrcode.value,
                        version: QrVersions.auto,
                        size: 200.0,
                      )
                    : const SizedBox(),
              ),
              Obx(
                () => _token.value.isNotEmpty
                    ? Container(
                        width: 200,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "无人值守",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                decoration: TextDecoration.none,
                              ),
                            ).marginOnly(left: 10),
                            SizedBox(
                              width: 40,
                              height: 20,
                              child: FlutterSwitch(
                                toggleSize: 20.0,
                                value: _on1.value,
                                onToggle: (bool value) {
                                  _on1.value = value;
                                  if (value) {
                                    _on2.value = true;
                                  }
                                },
                              ),
                            ).marginOnly(right: 10),
                          ],
                        ),
                      )
                    : const SizedBox(),
              ),
              const SizedBox(height: 15),
              Obx(
                () => _token.value.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          if (_on1.value) return;
                          _on2.value = !_on2.value;
                        },
                        child: Container(
                          width: 150,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _on2.value
                                ? Colors.redAccent
                                : Colors.blueAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: _on2.value
                                ? MainAxisAlignment.spaceBetween
                                : MainAxisAlignment.center,
                            children: [
                              _on2.value
                                  ? Icon(
                                      Icons.punch_clock_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ).marginOnly(left: 10)
                                  : const SizedBox(),
                              Text(
                                _on2.value ? "关闭服务" : "开启服务",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  decoration: TextDecoration.none,
                                ),
                              ).marginOnly(right: 10),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        ),
        Obx(
          () => _token.value.isNotEmpty
              ? Positioned(
                  top: 25,
                  left: 100,
                  child: GestureDetector(
                    child: Image.asset(
                      'assets/unlink.png',
                      width: 20,
                      height: 20,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Row(
                              children: [
                                Icon(Icons.info),
                                const SizedBox(width: 15),
                                const Text("确定解除绑定"),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  canaelBind();
                                  Navigator.of(context).pop();
                                },
                                child: const Text("确定"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text("取消"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                )
              : const SizedBox(),
        ),
        Obx(
          () => _token.value.isNotEmpty
              ? Positioned(
                  bottom: 20,
                  left: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //Text("门店ID: ${_orgId.value}", style: style),
                      Text("门店编号: ${_orgNo.value}", style: style),
                      Text("门店名称: ${_orgName.value}", style: style),
                      Text("clientNo: ${_clientNo.value}", style: style),
                      Text("位置描述: ${_location.value}", style: style),
                      Text("id: ${_id.value}", style: style),
                      Text("pw: ${_pw.value}", style: style),
                    ],
                  ),
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  bool busy = false;

  canaelBind() async {
    if (busy) {
      return;
    }
    busy = true;
    await _dio.request(
      "https://test.hzhexia.com/uop/backend/remote/app/clientUnbind",
      data: {"clientNo": _clientNo.value},
      options: Options(
        method: "POST",
        headers: {
          Headers.contentTypeHeader: 'application/json;charset=utf-8',
          Headers.acceptHeader: '*/*',
        },
      ),
    );
    _qrcode.value = "";
    _token.value = "";
    _orgId.value = "";
    _orgNo.value = "";
    _orgName.value = "";
    _clientNo.value = "";
    _location.value = "";

    box.remove('token');
    box.remove('orgId');
    box.remove('orgNo');
    box.remove('orgName');
    box.remove('clientNo');
    box.remove('location');

    var model = gFFI.serverModel;
    model.getInfo().then((v) {
      fetchQRCode(v[1], v[0]);
    });
    busy = false;
  }

  Future<void> fetchQRCode(String id, String pw) async {
    try {
      final response = await _dio.request(
        "https://test.hzhexia.com/uop/backend/remote/app/generateQrcode",
        data: {
          "appVersion": "1.0.0",
          "customField": jsonEncode({"id": id, "password": pw}),
          "mac": "00:1B:44:11:3A:B7",
          "sn": "1234567890",
        },
        options: Options(
          method: "POST",
          headers: {
            Headers.contentTypeHeader: 'application/json;charset=utf-8',
            Headers.acceptHeader: '*/*',
          },
        ),
      );
      _qrcode.value = response.data['data']['qrcode'];
      _qrcodeID.value = response.data['data']['qrcodeId'];
      _message.value = response.data['message'];

      if (_message.value == "OK") {
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          final r2 = _dio.request(
            "https://test.hzhexia.com/uop/backend/remote/app/bindStatusQuery",
            data: {"appVersion": "1.0.0", "qrcodeId": _qrcodeID.value},
            options: Options(
              method: "POST",
              headers: {
                Headers.contentTypeHeader: 'application/json;charset=utf-8',
                Headers.acceptHeader: '*/*',
              },
            ),
          );
          r2.then((value) {
            var code = value.data['code'];
            if (code == 400) {
              fetchQRCode(id, pw);
            } else if (code != 407) {
              _timer?.cancel();
              _qrcode.value = "";
              _token.value = value.data['data']['token'];
              _orgId.value = (value.data['data']['orgId']).toString();
              _orgNo.value = value.data['data']['orgNo'];
              _orgName.value = value.data['data']['orgName'];
              _clientNo.value = value.data['data']['clientNo'];
              _location.value = value.data['data']['location'];
              _id.value = id;
              _pw.value = pw;
            }
          }).catchError((e) {
            debugPrint(e.toString());
          });
        });
      } else {
        fetchQRCode(id, pw);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Widget _buildBlock({required Widget child}) {
    return buildRemoteBlock(
      block: _block,
      mask: true,
      use: canBeBlocked,
      child: child,
    );
  }

  Widget buildLeftPane(BuildContext context) {
    final isIncomingOnly = bind.isIncomingOnly();
    final isOutgoingOnly = bind.isOutgoingOnly();
    final children = <Widget>[
      if (!isOutgoingOnly) buildPresetPasswordWarning(),
      if (bind.isCustomClient())
        Align(alignment: Alignment.center, child: loadPowered(context)),
      Align(alignment: Alignment.center, child: loadLogo()),
      if (!isOutgoingOnly) buildIDBoard(context),
      FutureBuilder<Widget>(
        future: Future.value(
          Obx(() => const SizedBox()),
        ),
        builder: (_, data) {
          if (data.hasData) {
            if (isIncomingOnly) {
              if (isInHomePage()) {
                Future.delayed(Duration(milliseconds: 300), () {
                  _updateWindowSize();
                });
              }
            }
            return data.data!;
          } else {
            return const Offstage();
          }
        },
      ),
      buildPluginEntry(),
    ];
    if (isIncomingOnly) {
      children.addAll([
        Divider(),
        OnlineStatusWidget(
          onSvcStatusChanged: () {
            if (isInHomePage()) {
              Future.delayed(Duration(milliseconds: 300), () {
                _updateWindowSize();
              });
            }
          },
        ).marginOnly(bottom: 6, right: 6),
      ]);
    }
    final textColor = Theme.of(context).textTheme.titleLarge?.color;
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Container(
        width: isIncomingOnly ? 280.0 : 200.0,
        color: Theme.of(context).colorScheme.background,
        child: Stack(
          children: [
            Column(
              children: [
                SingleChildScrollView(
                  controller: _leftPaneScrollController,
                  child: Column(key: _childKey, children: children),
                ),
                Expanded(child: Container()),
              ],
            ),
            if (isOutgoingOnly)
              Positioned(
                bottom: 6,
                left: 12,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    child: Obx(
                      () => Icon(
                        Icons.settings,
                        color: _editHover.value
                            ? textColor
                            : Colors.grey.withOpacity(0.5),
                        size: 22,
                      ),
                    ),
                    onTap: () => {
                      if (DesktopSettingPage.tabKeys.isNotEmpty)
                        {
                          DesktopSettingPage.switch2page(
                            DesktopSettingPage.tabKeys[0],
                          ),
                        },
                    },
                    onHover: (value) => _editHover.value = value,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  buildRightPane(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ConnectionPage(),
    );
  }

  buildIDBoard(BuildContext context) {
    final model = gFFI.serverModel;
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 11),
      height: 57,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Container(
            width: 2,
            decoration: const BoxDecoration(color: MyTheme.accent),
          ).marginOnly(top: 5),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 25,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translate("ID"),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.titleLarge?.color?.withOpacity(0.5),
                          ),
                        ).marginOnly(top: 5),
                      ],
                    ),
                  ),
                  Flexible(
                    child: GestureDetector(
                      onDoubleTap: () {
                        Clipboard.setData(
                          ClipboardData(text: model.serverId.text),
                        );
                        showToast(translate("Copied"));
                      },
                      child: TextFormField(
                        controller: model.serverId,
                        readOnly: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                            top: 10,
                            bottom: 10,
                          ),
                        ),
                        style: TextStyle(fontSize: 22),
                      ).workaroundFreezeLinuxMint(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.arg != null) {
      _arg.value = widget.arg!;
      return;
    }
    _token.value = box.read('token') ?? "";
    if (_token.value.isNotEmpty) {
      _orgId.value = box.read('orgId') ?? "";
      _orgNo.value = box.read('orgNo') ?? "";
      _orgName.value = box.read('orgName') ?? "";
      _clientNo.value = box.read('clientNo') ?? "";
      _location.value = box.read('location') ?? "";
      var model = gFFI.serverModel;
      model.getInfo().then((v) {
        _id.value = v[1];
        _pw.value = v[0];
      });
    } else {
      var model = gFFI.serverModel;
      model.getInfo().then((v) {
        fetchQRCode(v[1], v[0]);
      });
    }
    _updateTimer = periodic_immediate(const Duration(seconds: 1), () async {
      await gFFI.serverModel.fetchID();
      final error = await bind.mainGetError();
      if (systemError != error) {
        systemError = error;
        setState(() {});
      }
      final v = await mainGetBoolOption(kOptionStopService);
      if (v != svcStopped.value) {
        svcStopped.value = v;
        setState(() {});
      }
      if (watchIsCanScreenRecording) {
        if (bind.mainIsCanScreenRecording(prompt: false)) {
          watchIsCanScreenRecording = false;
          setState(() {});
        }
      }
      if (watchIsProcessTrust) {
        if (bind.mainIsProcessTrusted(prompt: false)) {
          watchIsProcessTrust = false;
          setState(() {});
        }
      }
      if (watchIsInputMonitoring) {
        if (bind.mainIsCanInputMonitoring(prompt: false)) {
          watchIsInputMonitoring = false;
          // Do not notify for now.
          // Monitoring may not take effect until the process is restarted.
          // rustDeskWinManager.call(
          //     WindowType.RemoteDesktop, kWindowDisableGrabKeyboard, '');
          setState(() {});
        }
      }
      if (watchIsCanRecordAudio) {
        if (isMacOS) {
          Future.microtask(() async {
            if ((await osxCanRecordAudio() ==
                PermissionAuthorizeType.authorized)) {
              watchIsCanRecordAudio = false;
              setState(() {});
            }
          });
        } else {
          watchIsCanRecordAudio = false;
          setState(() {});
        }
      }
    });
    Get.put<RxBool>(svcStopped, tag: 'stop-service');
    rustDeskWinManager.registerActiveWindowListener(onActiveWindowChanged);

    screenToMap(window_size.Screen screen) => {
          'frame': {
            'l': screen.frame.left,
            't': screen.frame.top,
            'r': screen.frame.right,
            'b': screen.frame.bottom,
          },
          'visibleFrame': {
            'l': screen.visibleFrame.left,
            't': screen.visibleFrame.top,
            'r': screen.visibleFrame.right,
            'b': screen.visibleFrame.bottom,
          },
          'scaleFactor': screen.scaleFactor,
        };

    rustDeskWinManager.setMethodHandler((call, fromWindowId) async {
      debugPrint(
        "[Main] call ${call.method} with args ${call.arguments} from window $fromWindowId",
      );
      if (call.method == kWindowMainWindowOnTop) {
        windowOnTop(null);
      } else if (call.method == kWindowGetWindowInfo) {
        final screen = (await window_size.getWindowInfo()).screen;
        if (screen == null) {
          return '';
        } else {
          return jsonEncode(screenToMap(screen));
        }
      } else if (call.method == kWindowGetScreenList) {
        return jsonEncode(
          (await window_size.getScreenList()).map(screenToMap).toList(),
        );
      } else if (call.method == kWindowActionRebuild) {
        reloadCurrentWindow();
      } else if (call.method == kWindowEventShow) {
        await rustDeskWinManager.registerActiveWindow(call.arguments["id"]);
      } else if (call.method == kWindowEventHide) {
        await rustDeskWinManager.unregisterActiveWindow(call.arguments['id']);
      } else if (call.method == kWindowConnect) {
        await connectMainDesktop(
          call.arguments['id'],
          isFileTransfer: call.arguments['isFileTransfer'],
          isViewCamera: call.arguments['isViewCamera'],
          isTcpTunneling: call.arguments['isTcpTunneling'],
          isRDP: call.arguments['isRDP'],
          password: call.arguments['password'],
          forceRelay: call.arguments['forceRelay'],
          connToken: call.arguments['connToken'],
        );
      } else if (call.method == kWindowEventMoveTabToNewWindow) {
        final args = call.arguments.split(',');
        int? windowId;
        try {
          windowId = int.parse(args[0]);
        } catch (e) {
          debugPrint("Failed to parse window id '${call.arguments}': $e");
        }
        WindowType? windowType;
        try {
          windowType = WindowType.values.byName(args[3]);
        } catch (e) {
          debugPrint("Failed to parse window type '${call.arguments}': $e");
        }
        if (windowId != null && windowType != null) {
          await rustDeskWinManager.moveTabToNewWindow(
            windowId,
            args[1],
            args[2],
            windowType,
          );
        }
      } else if (call.method == kWindowEventOpenMonitorSession) {
        final args = jsonDecode(call.arguments);
        final windowId = args['window_id'] as int;
        final peerId = args['peer_id'] as String;
        final display = args['display'] as int;
        final displayCount = args['display_count'] as int;
        final windowType = args['window_type'] as int;
        final screenRect = parseParamScreenRect(args);
        await rustDeskWinManager.openMonitorSession(
          windowId,
          peerId,
          display,
          displayCount,
          screenRect,
          windowType,
        );
      } else if (call.method == kWindowEventRemoteWindowCoords) {
        final windowId = int.tryParse(call.arguments);
        if (windowId != null) {
          return jsonEncode(
            await rustDeskWinManager.getOtherRemoteWindowCoords(windowId),
          );
        }
      }
    });
    _uniLinksSubscription = listenUniLinks();

    if (bind.isIncomingOnly()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateWindowSize();
      });
    }
    WidgetsBinding.instance.addObserver(this);
  }

  _updateWindowSize() {
    RenderObject? renderObject = _childKey.currentContext?.findRenderObject();
    if (renderObject == null) {
      return;
    }
    if (renderObject is RenderBox) {
      final size = renderObject.size;
      if (size != imcomingOnlyHomeSize) {
        imcomingOnlyHomeSize = size;
        windowManager.setSize(getIncomingOnlyHomeSize());
      }
    }
  }

  @override
  void dispose() {
    _uniLinksSubscription?.cancel();
    Get.delete<RxBool>(tag: 'stop-service');
    _updateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      shouldBeBlocked(_block, canBeBlocked);
    }
  }

  Widget buildPluginEntry() {
    final entries = PluginUiManager.instance.entries.entries;
    return Offstage(
      offstage: entries.isEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...entries.map((entry) {
            return entry.value;
          }),
        ],
      ),
    );
  }
}

void setPasswordDialog({VoidCallback? notEmptyCallback}) async {
  final pw = await bind.mainGetPermanentPassword();
  final p0 = TextEditingController(text: pw);
  final p1 = TextEditingController(text: pw);
  var errMsg0 = "";
  var errMsg1 = "";
  final RxString rxPass = pw.trim().obs;
  final rules = [
    DigitValidationRule(),
    UppercaseValidationRule(),
    LowercaseValidationRule(),
    // SpecialCharacterValidationRule(),
    MinCharactersValidationRule(8),
  ];
  final maxLength = bind.mainMaxEncryptLen();

  gFFI.dialogManager.show((setState, close, context) {
    submit() {
      setState(() {
        errMsg0 = "";
        errMsg1 = "";
      });
      final pass = p0.text.trim();
      if (pass.isNotEmpty) {
        final Iterable violations = rules.where((r) => !r.validate(pass));
        if (violations.isNotEmpty) {
          setState(() {
            errMsg0 =
                '${translate('Prompt')}: ${violations.map((r) => r.name).join(', ')}';
          });
          return;
        }
      }
      if (p1.text.trim() != pass) {
        setState(() {
          errMsg1 =
              '${translate('Prompt')}: ${translate("The confirmation is not identical.")}';
        });
        return;
      }
      bind.mainSetPermanentPassword(password: pass);
      if (pass.isNotEmpty) {
        notEmptyCallback?.call();
      }
      close();
    }

    return CustomAlertDialog(
      title: Text(translate("Set Password")),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: translate('Password'),
                      errorText: errMsg0.isNotEmpty ? errMsg0 : null,
                    ),
                    controller: p0,
                    autofocus: true,
                    onChanged: (value) {
                      rxPass.value = value.trim();
                      setState(() {
                        errMsg0 = '';
                      });
                    },
                    maxLength: maxLength,
                  ).workaroundFreezeLinuxMint(),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: PasswordStrengthIndicator(password: rxPass)),
              ],
            ).marginSymmetric(vertical: 8),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: translate('Confirmation'),
                      errorText: errMsg1.isNotEmpty ? errMsg1 : null,
                    ),
                    controller: p1,
                    onChanged: (value) {
                      setState(() {
                        errMsg1 = '';
                      });
                    },
                    maxLength: maxLength,
                  ).workaroundFreezeLinuxMint(),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Obx(
              () => Wrap(
                runSpacing: 8,
                spacing: 4,
                children: rules.map((e) {
                  var checked = e.validate(rxPass.value.trim());
                  return Chip(
                    label: Text(
                      e.name,
                      style: TextStyle(
                        color: checked
                            ? const Color(0xFF0A9471)
                            : Color.fromARGB(255, 198, 86, 157),
                      ),
                    ),
                    backgroundColor: checked
                        ? const Color(0xFFD0F7ED)
                        : Color.fromARGB(255, 247, 205, 232),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        dialogButton("Cancel", onPressed: close, isOutline: true),
        dialogButton("OK", onPressed: submit),
      ],
      onSubmit: submit,
      onCancel: close,
    );
  });
}
