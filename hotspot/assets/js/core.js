var isvctopup = null;
var errorCodeMap = [];
errorCodeMap["coins.wait.expired"] = "You ran out of time to insert coin(s)";
errorCodeMap['coin.not.inserted'] = "Coin not inserted";
errorCodeMap["coinslot.cancelled"] = "Coinslot cancelled.";
errorCodeMap["coinslot.busy"] = "Coin slot is in use, try again later.";
errorCodeMap["coin.slot.banned"] = "You have been temporarily suspended from converting vouchers & inserting coins.";
errorCodeMap["coin.slot.notavailable"] = "Coin slot isn't available, try again later, or reconnect to the wifi network.";
errorCodeMap["no.internet.detected"] = "No internet connection, try again later";
errorCodeMap["product.hash.invalid"] = "Product hash has been tampered, your a hacker";
errorCodeMap["convertVoucher.empty"] = "Enter a voucher code.";
errorCodeMap["convertVoucher.invalid"] = "Invalid voucher.";
var totalCoinReceived = 0x0;
// --- Start of Web Audio API Setup ---

var audioCtx = new (window.AudioContext || window.webkitAudioContext)();

// Variable for the looping background music source
var insertCoinBgSource = null; 
// Buffer to hold the decoded background music
var insertCoinBgBuffer = null; 

// Buffer to hold the decoded coin count sound effect
var coinCountBuffer = null; 

// Function to load and decode ALL audio files
function initAudio() {
  // Load background music
  fetch("assets/insertcoinbg.mp3")
    .then(response => response.arrayBuffer())
    .then(data => audioCtx.decodeAudioData(data))
    .then(buffer => {
      insertCoinBgBuffer = buffer;
    })
    .catch(e => console.error("Error loading insertcoinbg.mp3: " + e));

  // Load coin received sound effect
  fetch("assets/coin-received.mp3")
    .then(response => response.arrayBuffer())
    .then(data => audioCtx.decodeAudioData(data))
    .then(buffer => {
      coinCountBuffer = buffer;
    })
    .catch(e => console.error("Error loading coin-received.mp3: " + e));
}

// --- Playback functions ---

// Function to play the looping background sound
function playInsertCoinBg() {
  if (isvctopup === true) return;
  // Stop any previous instances to prevent overlap
  if (insertCoinBgSource) {
    insertCoinBgSource.stop();
  }
  if (!insertCoinBgBuffer) {
    setTimeout(playInsertCoinBg, 1000); 
    toastr.error("Error playing insertcoinbg.");
    return;
  }

  insertCoinBgSource = audioCtx.createBufferSource();
  insertCoinBgSource.buffer = insertCoinBgBuffer;
  insertCoinBgSource.loop = true; // Enable looping
  insertCoinBgSource.connect(audioCtx.destination);
  insertCoinBgSource.start(0);
}

// Function to stop the looping background sound
function stopInsertCoinBg() {
  if (insertCoinBgSource) {
    insertCoinBgSource.stop();
  }
}

// Function to play the one-shot coin received sound
function playCoinCountSound() {
  if (!coinCountBuffer) return;

  // Create a new source every time. This allows the sound to be played
  // again, even if it's already playing (e.g., multiple coins inserted quickly).
  const source = audioCtx.createBufferSource();
  source.buffer = coinCountBuffer;
  source.connect(audioCtx.destination);
  source.start(0);
}


var voucher = getStorageValue("activeVoucher");
var insertingCoin = false;
var rateType = '1';
var voucherToConvert = '';
$('.header-text').html(headerText);
$(".footer-text").html(footerText);

$(document).ready(function () {
  initAudio();
  $('#saveVoucherButton').prop("hidden", true); 
  $("#cncl").prop("hidden", false);
  var _0x15a1b9 = false;
  var isinscoin = getStorageValue("isinsertingcoin");
  if (isinscoin === "true") {
    insertBtnAction();
    playInsertCoinBg();
  }
  $("#insertCoinModal").on("hidden.bs.modal", function () {
    setStorageValue("isinsertingcoin", "false");
    clearInterval(timer);
    timer = null;
    insertingCoin = false;
    stopInsertCoinBg();
    
    if (totalCoinReceived == 0x0) {
      $.ajax({
        'type': "POST",
        'url': "http://" + vendorIpAddress + "/cancelTopUp",
        'data': "voucher=" + voucher + '&mac=' + mac,
        'success': function (_0x4b4087) {},
        'error': function (_0x2c4fc6, _0x1977ec) {}
      });
    }
    resetInsertBtnUI();
  });
  if (loginError != '' && voucher != null && voucher != '') {
    _0x15a1b9 = true;
    removeStorageValue("isPaused");
    removeStorageValue("activeVoucher");
    voucher = '';
    toastr.error("Error resuming session, please try again.");
  }
  if (isMultiVendo) {
    $("#vendoSelectDiv").attr("style", "display: none");
    for (var _0x522dc8 = 0x0; _0x522dc8 < multiVendoAddresses.length; _0x522dc8++) {
      if (multiVendoAddresses[_0x522dc8].interfaceName == interfaceName) {
        vendorIpAddress = multiVendoAddresses[_0x522dc8].vendoIp;
      }
    }
  } else {
    $('#vendoSelectDiv').attr('style', "display: none");
  }
  if (!dataRateOption) {
    $("#dataInfoDiv").attr("style", "display: none");
    $("#dataInfoDiv2").attr("style", "display: none");
  }
  if (!showPauseTime) {
    $('#pauseTimeBtn').attr("style", "display: none");
  }
  if (!showExtendTimeButton) {
    var _0x460db5 = $("#insertBtn").attr("data-insert-type");
    if (_0x460db5 == "extend") {
      $("#insertBtn").attr("style", "display: none");
    }
  }
  if (!showVoucherConvert) {
    $('#voucherconvert').attr("style", "display: none");
  }
  if (macAsVoucherCode) {
    $("#voucherInput").attr("disabled", "disabled");
    var _0x450e34 = replaceAll(mac, ':');
    $("#voucherInput").val(_0x450e34);
    setStorageValue('activeVoucher', _0x450e34);
    voucher = _0x450e34;
  }
  var _0x1dfab3 = getStorageValue("isPaused");
  if (_0x1dfab3 == '1') {
    $("#pauseRemainTime").html(getStorageValue(voucher + "remain"));
  }
  var _0x5af07a = getStorageValue("redirectLogin");
  if (_0x5af07a == '1') {
    removeStorageValue('redirectLogin');
    location.reload();
    return;
  }
  var _0x50a99d = getStorageValue("forceLogout");
  if (_0x50a99d == '1') {
    removeStorageValue('forceLogout');
    setStorageValue("redirectLogin", '1');
    setStorageValue('ignoreSaveCode', '1');
    document.forcelogout.submit();
    return;
  }
  var _0x3623b2 = getStorageValue("insertCoinRefreshed");
  var _0x450e34 = replaceAll(mac, ':');
  var _0x25342f = getStorageValue('ignoreSaveCode');
  if (_0x25342f == null || _0x25342f == '0') {
    _0x25342f = '0';
  }
  if (_0x25342f != '1' && _0x3623b2 != '1' && !_0x15a1b9 && $('#voucherInput').length > 0x0) {
    $.ajax({
      'type': 'GET',
      'url': '/data/' + _0x450e34 + '.txt?query=' + new Date().getTime(),
      'success': function (_0x1f4fd6) {
        var _0x538def = _0x1f4fd6.split('#');
        voucher = _0x538def[0x0];
        $("#voucherInput").val(voucher);
      }
    });
  }
    // Start of Auto-Save Logic
  setInterval(function() {
    var currentVoucher = getStorageValue("activeVoucher");
    var currentTime = $("#remainTime").html();
    
    // Only save if we have a voucher and a time to save
    if (currentVoucher != null && currentVoucher != "" && currentTime != null) {
        setStorageValue(currentVoucher + 'remain', currentTime);
    }
  }, 5000); // 5000 milliseconds = 5 seconds
  
});
function replaceAll(_0x59c4f6, _0x486695) {
  var _0x5bf308 = _0x59c4f6;
  while (_0x5bf308.indexOf(_0x486695) > 0x0) {
    _0x5bf308 = _0x5bf308.replace(_0x486695, '');
  }
  return _0x5bf308;
}
if (voucher == null) {
  voucher = '';
}
if (voucher != '') {
  $("#voucherInput").val(voucher);
}
function cancelPause() {
  removeStorageValue("isPaused");
  removeStorageValue("activeVoucher");
  setStorageValue("forceLogout", '1');
  document.logout.submit();
}
function sendTelegramMessage(message) {
    if (enableTelegramMessages) { // Check if Telegram messages are enabled
        $.ajax({
            url: `https://api.telegram.org/bot${telegramBotToken}/sendMessage`,
            type: 'POST',
            data: {
                chat_id: telegramChatId,
                text: message
            },
            success: function(response) {
            },
            error: function(error) {
            }
        });
    } else {
        console.log("Telegram messages are disabled.");
    }
}
function promoBtnAction() {
  $("#promoRatesModal").modal('show');
  return false;
}
var timer = null;
var continuehiding = null;

function resetInsertBtnUI() {
  $("#insertLoading").hide();
  if (continuehiding === true) {
    return; 
  }
  if ($("#voucherconvertinput").length) {
    $("#voucherconvertinput").prop("disabled", false).css("opacity", "1");
  }
  if ($("#voucherconvertbtn").length) {
    $("#voucherconvertbtn").prop("disabled", false).css("opacity", "1");
  }
  $("#insertBtn").prop("disabled", false).css("opacity", "1");
  if ($("#resumeBtn").length) {
    $("#resumeBtn").prop("disabled", false).css("opacity", "1");
  }
  if ($("#pauseTimeBtn").length) {
    $("#pauseTimeBtn").prop("disabled", false).css("opacity", "1");
  } 
}
function insertBtnAction() {
  // Show loading spinner on Insert Coin
  $("#insertBtn").prop("disabled", true).css("opacity", "0.60");
  if ($("#resumeBtn").length) {
    $("#resumeBtn").prop("disabled", true).css("opacity", "0.65");
  }
  if ($("#voucherconvertbtn").length) {
    $("#voucherconvertbtn").prop("disabled", true).css("opacity", "0.65");
  }
  if ($("#voucherconvertinput").length) {
    $("#voucherconvertinput").prop("disabled", true).css("opacity", "0.65");
  }
  if ($("#pauseTimeBtn").length) {
    $("#pauseTimeBtn").prop("disabled", true).css("opacity", "0.65");
  }
  $("#insertLoading").show();


  removeStorageValue('ignoreSaveCode');
  setStorageValue("insertCoinRefreshed", '0');
  $("#waitTimer").prop('hidden', false);
  $("#progressDiv").attr("style", "width: 100%");
  $("#saveVoucherButton").prop('hidden', true);
  $("#cncl").prop("hidden", false);
  totalCoinReceived = 0x0;

  var _0x16e8f0 = getStorageValue("totalCoinReceived");
  if (_0x16e8f0 != null) {
    totalCoinReceived = _0x16e8f0;
  }

  $("#totalCoin").html('0');
  $("#totalTime").html(insertcoinDhms(parseInt(0x0)));

  var _0x3f89f8 = $('#saveVoucherButton').attr('data-save-type');

  if (_0x3f89f8 != "extend") {
    $.ajax({
      type: "GET",
      url: "/status",
      success: function (_0x4f120e, _0x1a6a8a, _0x2cc13f) {
        if (_0x4f120e.indexOf("IAMNOTLOGINSTRINGPLEASEDONTREMOVE") < 0x0) {
          location.reload();
        } else {
          callTopupAPI(0x0);  
        }
      }
    });
  } else {
    callTopupAPI(0x0);  
  }
  // Prevent back button
  history.pushState(null, null, location.href);
  window.onpopstate = function () {
    history.go(1);
  };
  return false;
}
$("#promoRatesModal").on("shown.bs.modal", function (_0xca0c93) {
  populatePromoRates(0x0);
});
function populatePromoRates(_0x147aea) {
  $.ajax({
    'type': "GET",
    'url': 'http://' + vendorIpAddress + "/getRates?rateType=" + rateType + "&date=" + new Date().getTime(),
    'crossOrigin': true,
    'contentType': "text/plain",
    'success': function (_0x564d96) {
      var _0x320775 = _0x564d96.split('|');
      var _0x430a37 = '';
      _0x430a37 = _0x430a37 + "<table style='width:100%';>";
      _0x430a37 = _0x430a37 + "<tr class='thead-dark' align='center'>";
      _0x430a37 = _0x430a37 + "<th>Amount</th>";
      _0x430a37 = _0x430a37 + '<th>Time</th>';
      _0x430a37 = _0x430a37 + "<th>Validity</th>";
      _0x430a37 = _0x430a37 + '</tr>';
      for (r in _0x320775) {
        var _0x39d1bc = _0x320775[r].split('#');
        var _0x1bc846 = _0x39d1bc[0x2];
        var _0x35f383 = Math.floor(_0x1bc846 / 0x5a0);
        var _0x1f07f9 = _0x1bc846 % 0x5a0;
        var _0x5e17cf = Math.floor(_0x1f07f9 / 0x3c);
        var _0x57f941 = _0x1f07f9 % 0x3c;
        var _0x219fc1 = _0x35f383 > 0x0 && _0x5e17cf == 0x0 && _0x57f941 == 0x0 ? _0x219fc1 = _0x35f383 + 'd:0h:0m' : _0x35f383 > 0x0 && _0x5e17cf > 0x0 && _0x57f941 == 0x0 ? _0x219fc1 = _0x35f383 + 'd:' + _0x5e17cf + 'h:0m' : _0x35f383 > 0x0 && _0x5e17cf == 0x0 && _0x57f941 > 0x0 ? _0x219fc1 = _0x35f383 + "d:0h:" + _0x57f941 + 'm' : _0x35f383 > 0x0 && _0x5e17cf > 0x0 && _0x57f941 > 0x0 ? _0x219fc1 = _0x35f383 + 'd:' + _0x5e17cf + 'h:' + _0x57f941 + 'm' : _0x35f383 == 0x0 && _0x5e17cf > 0x0 && _0x57f941 == 0x0 ? _0x219fc1 = _0x5e17cf + 'h:0m' : _0x35f383 == 0x0 && _0x5e17cf > 0x0 && _0x57f941 > 0x0 ? _0x219fc1 = _0x5e17cf + 'h:' + _0x57f941 + 'm' : _0x219fc1 = _0x57f941 + 'm';
        var _0x3b09c5 = _0x39d1bc[0x3];
        var _0x194e67 = Math.floor(_0x3b09c5 / 0x5a0);
        var _0x5834ab = _0x3b09c5 % 0x5a0;
        var _0x27feb1 = Math.floor(_0x5834ab / 0x3c);
        var _0x2ab8c7 = _0x5834ab % 0x3c;
        var _0x1f718e = _0x194e67 > 0x0 && _0x27feb1 == 0x0 && _0x2ab8c7 == 0x0 ? _0x1f718e = _0x194e67 + 'd' : _0x194e67 > 0x0 && _0x27feb1 > 0x0 && _0x2ab8c7 == 0x0 ? _0x1f718e = _0x194e67 + 'd:' + _0x27feb1 + 'h' : _0x194e67 > 0x0 && _0x27feb1 == 0x0 && _0x2ab8c7 > 0x0 ? _0x1f718e = _0x194e67 + 'd:' + _0x2ab8c7 + 'm' : _0x194e67 > 0x0 && _0x27feb1 > 0x0 && _0x2ab8c7 > 0x0 ? _0x1f718e = _0x194e67 + 'd:' + _0x27feb1 + 'h:' + _0x2ab8c7 + 'm' : _0x194e67 == 0x0 && _0x27feb1 > 0x0 && _0x2ab8c7 == 0x0 ? _0x1f718e = _0x27feb1 + 'h' : _0x194e67 == 0x0 && _0x27feb1 > 0x0 && _0x2ab8c7 > 0x0 ? _0x1f718e = _0x27feb1 + 'h:' + _0x2ab8c7 + 'm' : _0x1f718e = _0x2ab8c7 + 'm';
        _0x430a37 = _0x430a37 + "<tr align='center'>";
        _0x430a37 = _0x430a37 + "<td>" + "&#8369;" + _0x39d1bc[0x1] + "</td>";
        _0x430a37 = _0x430a37 + "<td>" + _0x219fc1 + "</td>";
        _0x430a37 = _0x430a37 + "<td>" + _0x1f718e + "</td>";
        _0x430a37 = _0x430a37 + "</tr>";
      }
      _0x430a37 = _0x430a37 + "</table>";
      $("#ratesBody").html(_0x430a37);
    },
    'error': function (_0x395760, _0x410911) {
      setTimeout(function () {
        if (_0x147aea < 0x2) {
          populatePromoRates(_0x147aea + 0x1);
        }
      }, 0x3e8);
    }
  });
}
function onRateTypeChange(_0xea90d4) {
  rateType = $(_0xea90d4).val();
  populatePromoRates(0x0);
}


function callTopupAPI(_0x59b293) {
  // Add this block at the beginning
  var isinscoin = getStorageValue("isinsertingcoin");
  if (isinscoin === false) {
    sendTelegramMessage(`${mac} is trying to insert coin.`);
  }

  $("#cncl").html("Cancel");
  $("#vcCodeDiv").attr("style", "display: block");
  var _0x3fd258 = $("#saveVoucherButton").attr("data-save-type");
  if (_0x3fd258 != "extend" && totalCoinReceived == 0x0 && !macAsVoucherCode) {
    var _0x47ee2d = getStorageValue('activeVoucher');
    if (_0x47ee2d != null) {
      voucher = '';
      $("#voucherInput").val('');
      removeStorageValue("activeVoucher");
    }
  }
  var _0x326adf = '';
  if (typeof uIp !== 'undefined') {
    _0x326adf = "&ipAddress=" + uIp;
  }
  if (_0x3fd258 == 'extend') {
    extendTimeCriteria = "&extendTime=1";
  } else {
    extendTimeCriteria = "&extendTime=0";
  }
  $.ajax({
    'type': 'POST',
    'url': "http://" + vendorIpAddress + "/topUp",
    'data': "voucher=" + voucher + "&mac=" + mac + _0x326adf + extendTimeCriteria,
    'success': function (_0x52ea58) {
      if (_0x52ea58.status == "true") {
        voucher = _0x52ea58.voucher;
        $("#insertCoinModal").modal("show");
        insertingCoin = true;
        $("#codeGenerated").html(voucher);
        $("#codeGeneratedBlock").attr('style', "display: none");
        if (timer == null) {
          timer = setInterval(checkCoin, 500);
        }
        if (isMultiVendo) {
          $("#insertCoinModalTitle").html("Please insert coin at " + interfaceName);
        }
        playInsertCoinBg();
        setStorageValue("isinsertingcoin", "true");
      } else {
        notifyCoinSlotError(_0x52ea58.errorCode);
        clearInterval(timer);
        timer = null;
      }
    },
    'error': function (_0x24580b, _0x407eb3) {
      setTimeout(function () {
        if (_0x59b293 < 0x3) {
          callTopupAPI(_0x59b293 + 0x1);
        } else {
          setStorageValue("isinsertingcoin", "false");
          notifyCoinSlotError("coin.slot.notavailable");
        }
      }, 1500);
    }
  });
}
function saveVoucherBtnAction() {
  setStorageValue("activeVoucher", voucher);
  removeStorageValue('totalCoinReceived');
  $("#voucherInput").val(voucher);
  clearInterval(timer);
  timer = null;
  continuehiding = true;
  stopInsertCoinBg();
  if ($(".loginRemainTime").length) {
     $(".loginRemainTime").html(`
        <div class="spinner-border text-primary" role="status" style="width: 2rem; height: 2rem; border-width: 0.17em;">
           <span class="sr-only">Loading...</span>
        </div>
    `);
  }
  
  if ($("#remainTime").length) {        
     if(typeof remainingTimer !== 'undefined') {
        clearInterval(remainingTimer);
     }
     $("#remainTime").html(`
        <div class="spinner-border text-primary" role="status" style="width: 2rem; height: 2rem; border-width: 0.17em;">
           <span class="sr-only">Loading...</span>
        </div>
    `);
  }

  $.ajax({
    'type': "POST",
    'url': "http://" + vendorIpAddress + "/useVoucher",
    'data': "voucher=" + voucher,
    'success': function (_0x1796ef) {
      totalCoinReceived = 0x0;
      if (_0x1796ef.status == "true") {
        setStorageValue(voucher + "tempValidity", _0x1796ef.validity);
        if (isvctopup !== true) {
           toastr.success("Successfully claim your time!");
        } else if (isvctopup === true) {
           var _0xa94a94 = $("#voucherconvertinput").val();
           $("#voucherconvertinput").val("");
        }
        var _0x1a7c7c = $("#saveVoucherButton").attr('data-save-type');
        if (_0x1a7c7c == 'extend') {
          $.ajax({
            'type': "POST",
            'url': "/logout",
            'data': "erase-cookie=true",
            'success': function (_0x2da238) {
              setStorageValue('reLogin', '1');
              location.reload();
            }
          });
        } else {
          setTimeout(function () {
            newLogin();
          }, 0xbb8);
        }
      } else {
        notifyCoinSlotError(_0x1796ef.errorCode);
      }
    },
    'error': function (_0x413188, _0x463d8d) {
      if (totalCoinReceived > 0x0) {
        toastr.error("Failed to resume time, please manually do it.");
        setTimeout(function () {
          newLogin();
        }, 0xbb8);
      }
    }
  });
}
function checkCoin() {
  $.ajax({
    'type': 'POST',
    'url': "http://" + vendorIpAddress + '/checkCoin',
    'data': "voucher=" + voucher,
    'success': function (_0x472e01) {
      $("#noticeDiv").attr('style', "display: none");
      if (_0x472e01.status == "true") {
        totalCoinReceived = parseInt(_0x472e01.totalCoin);
        $("#totalCoin").html(_0x472e01.totalCoin);
        $("#totalTime").html(insertcoinDhms(parseInt(_0x472e01.timeAdded)));
        if (true && !macAsVoucherCode) {
          $("#codeGeneratedBlock").attr("style", "display: block");
          $("#totalData").html(_0x472e01.data);
          $('#voucherInput').val(voucher);
        }
        setStorageValue("activeVoucher", voucher);
        setStorageValue("totalCoinReceived", totalCoinReceived);
        setStorageValue(voucher + "tempValidity", _0x472e01.validity);
        notifyCoinSuccess(_0x472e01.newCoin);
        if (isvctopup === true) {
          saveVoucherBtnAction();
        }
      } else {
        if (_0x472e01.errorCode == "coin.is.reading") {
          $('#noticeDiv').attr("style", "display: block");
          $('#noticeText').html("Verifying, please wait..");
          if ($("#cncl").length) {
            $("#cncl").prop("disabled", true).css("opacity", "0.65");
          }
          if ($("#saveVoucherButton").length) {
            $("#saveVoucherButton").prop("disabled", true).css("opacity", "0.65");
          }
        } else {
          if (_0x472e01.errorCode == 'coin.not.inserted') {
            setStorageValue(voucher + "tempValidity", _0x472e01.validity);
            var _0x1b4aca = parseInt(parseInt(_0x472e01.remainTime) / 0x3e8);
            var _0x25cc5d = parseFloat(_0x472e01.waitTime);
            var _0x1a1f1e = parseInt(_0x1b4aca * 0x3e8 / _0x25cc5d * 0x64);
            totalCoinReceived = parseInt(_0x472e01.totalCoin);
            if (totalCoinReceived > 0x0) {
              $("#saveVoucherButton").prop("hidden", false);
              $('#cncl').prop("hidden", true);
            }
            if (_0x1b4aca == 0x0) {
              $("#insertCoinModal").modal("hide");
              stopInsertCoinBg();
              if (totalCoinReceived > 0x0) {
                toastr.success("Successfully claim your time!");
                var _0xc911ca = $("#saveVoucherButton").attr("data-save-type");
                setTimeout(function () {
                  if (_0xc911ca == "extend") {
                    $.ajax({
                      'type': "POST",
                      'url': "/logout",
                      'data': 'erase-cookie=true',
                      'success': function (_0x39b0bb) {
                        setStorageValue("reLogin", '1');
                        location.reload();
                      }
                    });
                  } else {
                    newLogin();
                  }
                }, 0xbb8);
              } else {
                notifyCoinSlotError("coins.wait.expired");
              }
            } else {
              totalCoinReceived = parseInt(_0x472e01.totalCoin);
              if (totalCoinReceived > 0x0 && !macAsVoucherCode) {
                $("#saveVoucherButton").prop("hidden", false);
                $("#cncl").prop('hidden', true);
                $("#codeGeneratedBlock").attr('style', "display: block");
              }
              $("#totalCoin").html(_0x472e01.totalCoin);
              $("#totalData").html(_0x472e01.data);
              $('#totalTime').html(insertcoinDhms(parseInt(_0x472e01.timeAdded)));
              $('#waitTimer').html(_0x1b4aca);
              $("#progressDiv").attr("style", "width: " + _0x1a1f1e + '%');
            }
          } else {
            if (_0x472e01.errorCode == "coinslot.busy") {
              stopInsertCoinBg();
              clearInterval(timer);
              $("#insertCoinModal").modal("hide");
              if (totalCoinReceived == 0x0) {
                if (isvctopup === true) return;
                notifyCoinSlotError("coinslot.cancelled");
              } else {
                toastr.success("Successfully claim your time!");
                var _0xc911ca = $("#saveVoucherButton").attr("data-save-type");
                setTimeout(function () {
                  if (_0xc911ca == "extend") {
                    setStorageValue("reLogin", '1');
                    document.logout.submit();
                  } else {
                    newLogin();
                  }
                }, 0xbb8);
              }
            } else {
              notifyCoinSlotError(_0x472e01.errorCode);
              clearInterval(timer);
            }
          }
        }
      }
    },
    'error': function (_0x58bbad, _0x4ad029) {
      console.log("error!!!");
    }
  });
}
function convertVoucherAction() {
  var _0xa94a94 = $("#convertVoucherCode").val();
  if (isvctopup === true) {
    var _0xa94a94 = $("#voucherconvertinput").val();
    $("#convertCoucherCode").val(_0xa94a94);
  }
  if (_0xa94a94 != '') {
    voucherToConvert = _0xa94a94;
    $('#convertBtn').prop("disabled", true);
    $.ajax({
      'type': "POST",
      'url': "http://" + vendorIpAddress + "/convertVoucher",
      'data': "voucher=" + voucher + '&convertVoucher=' + voucherToConvert,
      'success': function (_0x29dc8e) {
        if (_0x29dc8e.status == 'true') {
          toastr.success("Voucher code " + _0xa94a94 + " successfully redeemed");
        } else {
          notifyCoinSlotError("convertVoucher.invalid");
          if (isvctopup === true) {
              isvctopup = false
              clearInterval(timer);
              timer = null;
              insertingCoin = false;
              stopInsertCoinBg();

              if (totalCoinReceived == 0x0) {
                 $.ajax({
                 'type': "POST",
                 'url': "http://" + vendorIpAddress + "/cancelTopUp",
                 'data': "voucher=" + voucher + '&mac=' + mac,
                 'success': function (_0x4b4087) {},
                 'error': function (_0x2c4fc6, _0x1977ec) {}
                 });
              }
          }
        }
        $("#convertVoucherCode").val('');
        $("#convertBtn").prop("disabled", false);
        voucherToConvert = '';
      },
      'error': function () {
        notifyCoinSlotError("convertVoucher.invalid");
        $("#convertVoucherCode").val('');
        $("#convertBtn").prop("disabled", false);
        voucherToConvert = '';
        if (isvctopup === true) {
           isvctopup = false
           clearInterval(timer);
           timer = null;
           insertingCoin = false;
           stopInsertCoinBg();

           if (totalCoinReceived == 0x0) {
              $.ajax({
              'type': "POST",
              'url': "http://" + vendorIpAddress + "/cancelTopUp",
              'data': "voucher=" + voucher + '&mac=' + mac,
              'success': function (_0x4b4087) {},
              'error': function (_0x2c4fc6, _0x1977ec) {}
              });
           }
        }
      }
    });
  } else {
    notifyCoinSlotError("convertVoucher.empty");
    if (isvctopup === true) {
       isvctopup = false
       clearInterval(timer);
       timer = null;
       insertingCoin = false;
       stopInsertCoinBg();

       if (totalCoinReceived == 0x0) {
       $.ajax({
         'type': "POST",
         'url': "http://" + vendorIpAddress + "/cancelTopUp",
         'data': "voucher=" + voucher + '&mac=' + mac,
         'success': function (_0x4b4087) {},
         'error': function (_0x2c4fc6, _0x1977ec) {}
         });
       }
    }
  }
}
function notifyCoinSlotError(_0x4e4a96) {
  toastr.error(
    errorCodeMap[_0x4e4a96]
  );
  resetInsertBtnUI();
}
function notifyCoinSuccess(_0x1646b2) {
  if (isvctopup !== true) {
    playCoinCountSound();
      // Message with total amount removed
     var message = `(${mac}) inserted (${_0x1646b2}) coin(s)`;
     sendTelegramMessage(message);
  }
  if ($("#cncl").length) {
    $("#cncl").prop("disabled", false).css("opacity", "1");
  }
  if ($("#saveVoucherButton").length) {
    $("#saveVoucherButton").prop("disabled", false).css("opacity", "1");
  }
  if (isvctopup === true) {
    var _0xa94a94 = $("#voucherconvertinput").val();
    // Message with total amount removed
    var message = `${mac} converted voucher: ${_0xa94a94} successfully, amount: ₱ (${_0x1646b2})`;
    sendTelegramMessage(message);
  }
}

function secondsToDhms(_0x4547ee) {
  _0x4547ee = Number(_0x4547ee);
  var _0x262f0b = Math.floor(_0x4547ee / 86400);
  var _0x17dcea = Math.floor(_0x4547ee % 86400 / 0xe10);
  var _0x8181ae = Math.floor(_0x4547ee % 0xe10 / 0x3c);
  var _0xea4196 = Math.floor(_0x4547ee % 0x3c);
  var _0x3edcf3 = _0x262f0b > 0x0 ? _0x262f0b + (_0x262f0b == 0x1 ? "<span style='font-family:Roboto;font-weight:400;font-size:50.666%'> D. </span>" : "<span style='font-family:Roboto;font-weight:400;font-size:50.666%'> D. </span>") : '';
  var _0x378cac = _0x17dcea > 0x0 ? _0x17dcea + (_0x17dcea == 0x1 ? "<span style='font-family:Roboto;font-weight:400;font-size:50.666%'> HR. </span>" : "<span style='font-family:Roboto;font-weight:400;font-size:50.666%'> HR. </span>") : '';
  var _0x5030ae = _0x8181ae > 0x0 ? _0x8181ae + (_0x8181ae == 0x1 ? "<span style='font-family:Roboto;font-weight:400;font-size:50.666%;'> MIN. </span>" : "<span style='font-family:Roboto;font-weight:400;font-size:50.666%;'> MIN. </span>") : '';
  var _0x52b3e0 = _0xea4196 > 0x0 ? _0xea4196 + (_0xea4196 == 0x1 ? '' : '') : '0';
  return _0x3edcf3 + "<span style='font-family:Roboto;font-weight:400;font-size:50.666%'> </span>" + _0x378cac + "<span style='font-family:Roboto;font-weight:400;font-size:50.666%'> </span>" + _0x5030ae + "<span style='font-family:Roboto;font-weight:400;font-size:50.666%;'> </span>" + _0x52b3e0 + "<span style='font-family:Roboto;font-weight:400;font-size:50.666%'> SEC</span>";
}
function insertcoinDhms(_0x22c955) {
  _0x22c955 = Number(_0x22c955);
  var _0x6a4445 = Math.floor(_0x22c955 / 86400);
  var _0x538254 = Math.floor(_0x22c955 % 86400 / 0xe10);
  var _0x452fe0 = Math.floor(_0x22c955 % 0xe10 / 0x3c);
  var _0x134931 = _0x6a4445 > 0x0 ? _0x6a4445 + (_0x6a4445 == 0x1 ? 'd' : 'd') : '';
  var _0x233272 = _0x538254 > 0x0 ? _0x538254 + (_0x538254 == 0x1 ? 'h' : 'h') : '';
  var _0x151a99 = _0x452fe0 > 0x0 ? _0x452fe0 + (_0x452fe0 == 0x1 ? '' : '') : '0';
  return _0x134931 + " " + _0x233272 + " " + _0x151a99 + 'm';
}
function setStorageValue(_0x1ee526, _0x595082) {
  if (localStorage != null) {
    localStorage.setItem(_0x1ee526, _0x595082);
  } else {
    setCookie(_0x1ee526, _0x595082, 0x16c);
  }
}
function removeStorageValue(_0x3e6ccd) {
  if (localStorage != null) {
    localStorage.removeItem(_0x3e6ccd);
  } else {
    eraseCookie(_0x3e6ccd);
  }
}
function pause() {
  var _0x65a10a = getStorageValue("activeVoucher");
  setStorageValue("isPaused", '1');
  setStorageValue(_0x65a10a + 'remain', $("#remainTime").html());
  document.logout.submit();
    // Prevent back button
  history.pushState(null, null, location.href);
  window.onpopstate = function () {
    history.go(1);
  };
}
function resume() {
  removeStorageValue('isPaused');
  removeStorageValue("isPaused");
  removeStorageValue("activeVoucher");
  removeStorageValue("ignoreSaveCode");
  location.reload();
    // Prevent back button
  history.pushState(null, null, location.href);
  window.onpopstate = function () {
    history.go(1);
  };
}
function getStorageValue(_0xf64a5e) {
  return localStorage != null ? localStorage.getItem(_0xf64a5e) : getCookie(_0xf64a5e);
}
function setCookie(_0x493542, _0x3f9e7a, _0x1211bb) {
  var _0x1871a6 = '';
  if (_0x1211bb) {
    var _0x2328d1 = new Date();
    _0x2328d1.setTime(_0x2328d1.getTime() + _0x1211bb * 0x18 * 0x3c * 0x3c * 0x3e8);
    _0x1871a6 = "; expires=" + _0x2328d1.toUTCString();
  }
  document.cookie = _0x493542 + '=' + (_0x3f9e7a || '') + _0x1871a6 + "; path=/";
}
function getCookie(_0x29546f) {
  var _0x589cb0 = _0x29546f + '=';
  var _0x387563 = document.cookie.split(';');
  for (var _0x4796e3 = 0x0; _0x4796e3 < _0x387563.length; _0x4796e3++) {
    var _0x421727 = _0x387563[_0x4796e3];
    while (_0x421727.charAt(0x0) == " ") {
      _0x421727 = _0x421727.substring(0x1, _0x421727.length);
    }
    if (_0x421727.indexOf(_0x589cb0) == 0x0) {
      return _0x421727.substring(_0x589cb0.length, _0x421727.length);
    }
  }
  return null;
}
function eraseCookie(_0x5fa9bb) {
  document.cookie = _0x5fa9bb + "=; Max-Age=-99999999;";
}
function fetchValidity(_0x1576f8) {
  if (_0x1576f8 > 0x5) {
    fallbackValidity();
    return;
  }
  var _0x5a9e8f = replaceAll(mac, ':');
  $.ajax({
    'type': 'GET',
    'url': "/data/" + _0x5a9e8f + ".txt?query=" + new Date().getTime(),
    'success': function (_0x5f11b4) {
      if (_0x5f11b4.length > 0x32) {
        setTimeout(function () {
          fetchValidity(_0x1576f8++);
        }, 0x3e8);
        return;
      }
      var _0x474b9a = _0x5f11b4.split('#');
      var _0x42e44b = _0x474b9a[0x1];
      var _0x10bc46 = null;
      if (_0x42e44b.length > 0xf) {
        _0x10bc46 = new Date(Date.parse(_0x42e44b));
      } else {
        if (_0x42e44b.length > 0x8) {
          var _0x41bfa8 = _0x42e44b.split(" ");
          var _0x1909eb = new Date().getFullYear();
          _0x10bc46 = new Date(Date.parse(_0x41bfa8[0x0] + '/' + _0x1909eb + " " + _0x41bfa8[0x1]));
        } else {
          if (_0x42e44b.length == 0x0) {
            _0x10bc46 = null;
          } else {
            var _0x4fdae5 = new Date();
            var _0x5ecec0 = _0x4fdae5.getMonth() + 0x1;
            var _0x3d6542 = _0x4fdae5.getDate();
            var _0x1909eb = _0x4fdae5.getFullYear();
            _0x10bc46 = new Date(Date.parse(_0x5ecec0 + '/' + _0x3d6542 + '/' + _0x1909eb + " " + _0x42e44b));
          }
        }
      }
      if (_0x10bc46 != null) {
        $("#expirationTime").html(_0x10bc46.toLocaleString());
      } else {
        $("#expirationTime").html("No Expiration");
      }
    },
    'error': function (_0x2b59e3) {
      fallbackValidity();
    }
  });
}
function newLogin() {
  location.reload();
}
function vctopup(_0x59b293) {
  var _0xa94a94 = $("#voucherconvertinput").val();
  if (_0xa94a94 == "" || _0xa94a94 == null || _0xa94a94.length <= 4 || _0xa94a94.length > 10) {
    if (_0xa94a94 == "" || _0xa94a94 == null) {
      notifyCoinSlotError("convertVoucher.empty");
    } else if (_0xa94a94.length <= 4 || _0xa94a94.length > 10) {
      notifyCoinSlotError("convertVoucher.invalid");
    }
    return;
  }
  isvctopup = true
  
    $("#insertBtn").prop("disabled", true).css("opacity", "0.60");
  if ($("#resumeBtn").length) {
    $("#resumeBtn").prop("disabled", true).css("opacity", "0.65");
  }
  if ($("#voucherconvertbtn").length) {
    $("#voucherconvertbtn").prop("disabled", true).css("opacity", "0.65");
  }
  if ($("#voucherconvertinput").length) {
    $("#voucherconvertinput").prop("disabled", true).css("opacity", "0.65");
  }
  if ($("#pauseTimeBtn").length) {
    $("#pauseTimeBtn").prop("disabled", true).css("opacity", "0.65");
  }
  // Add this block at the beginning
  if (_0x59b293 === 0) {
    sendTelegramMessage(`${mac} attempted to convert voucher.`);
  }

  $("#cncl").html("Cancel");
  $("#vcCodeDiv").attr("style", "display: block");
  var _0x3fd258 = $("#saveVoucherButton").attr("data-save-type");
  // clear voucher cookie if the user is not extending
  if (_0x3fd258 != "extend" && totalCoinReceived == 0x0 && !macAsVoucherCode) {
    var _0x47ee2d = getStorageValue('activeVoucher');
    if (_0x47ee2d != null) {
      voucher = '';
      $("#voucherInput").val('');
      removeStorageValue("activeVoucher");
    }
  }
  var _0x326adf = '';
  if (typeof uIp !== 'undefined') {
    _0x326adf = "&ipAddress=" + uIp;
  }
  if (_0x3fd258 == 'extend') {
    extendTimeCriteria = "&extendTime=1";
  } else {
    extendTimeCriteria = "&extendTime=0";
  }
  $.ajax({
    'type': 'POST',
    'url': "http://" + vendorIpAddress + "/topUp",
    'data': "voucher=" + voucher + "&mac=" + mac + _0x326adf + extendTimeCriteria,
    'success': function (_0x52ea58) {
      if (_0x52ea58.status == "true") {
        voucher = _0x52ea58.voucher;
        insertingCoin = true;
        $("#codeGenerated").html(voucher);
        $("#codeGeneratedBlock").attr('style', "display: none");
        if (timer == null) {
          timer = setInterval(checkCoin, 500);
        }
        if (isMultiVendo) {
          $("#insertCoinModalTitle").html("Please insert coin at " + interfaceName);
        }
        // success 
        convertVoucherAction();
      } else {
        notifyCoinSlotError(_0x52ea58.errorCode);
        clearInterval(timer);
        timer = null;
      }
    },
    'error': function (_0x24580b, _0x407eb3) {
      setTimeout(function () {
        if (_0x59b293 < 0x3) {
          vctopup(_0x59b293 + 0x1);
        } else {
          notifyCoinSlotError("coin.slot.notavailable");
        }
      }, 1500);
    }
  });
}
function fallbackValidity() {
  var _0xb02a02 = getStorageValue(voucher + "validity");
  if (_0xb02a02 != null) {
    var _0x5447cf = new Date();
    var _0x105896 = new Date(parseInt(_0xb02a02));
    if (_0x105896.getTime() < _0x5447cf.getTime()) {
      removeStorageValue(voucher + "validity");
      removeStorageValue(voucher + "tempValidity");
      $("#expirationTime").html("Not Available");
    } else {
      $("#expirationTime").html(_0x105896.toLocaleString());
    }
  } else {
    $("#expirationTime").html("Not Available");
  }
}