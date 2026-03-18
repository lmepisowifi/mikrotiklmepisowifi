// this is to enable multi vendo autoselect setup via interface, set to true when multi vendo is supported
var isMultiVendo = false;

// list here all node mcu address for multi vendo setup
var multiVendoAddresses = [
    {
        vendoName: "Vendo 1", // change accordingly to your vendo name
        vendoIp: "10.0.0.5", // change accordingly to your vendo ip
        hotspotAddress: "10.0.0.1", // for hotspot address option = 1
        interfaceName: "Vendo 1", // for hotspot interface name option = 2
    },
    {
        vendoName: "Vendo 2", // change accordingly to your vendo name
        vendoIp: "10.0.1.5", // change accordingly to your vendo ip
        hotspotAddress: "10.0.0.1", // for hotspot address option = 1
        interfaceName: "Vendo 2", // for hotspot interface name option = 2
    }
];

// 0 means its login by username only, 1 = means if login by username + password
var loginOption = 0; // replace 1 if you want login voucher by username + password

var dataRateOption = false; // replace true if you enable data rates
// put here the default selected address
var vendorIpAddress = "10.0.0.5";

// hide pause time / logout true = you want to show pause / logout button
var showPauseTime = true;

// enable extend time button for customers
var showExtendTimeButton = true;

// hide or show the convert voucher box in the login and status page.
var showVoucherConvert = true;

// leave as it is.
var macAsVoucherCode = true;

var headerText = "The best connections wifi machine";

var footerText = ".";

// Enable sliding text
var isSlidingTextEnabled = false; // Set to true to enable sliding text
var slidingTextContent = "LIMITED PROMO: ₱5 FOR 2 HOURS.";

// telegram for amount of coins inserted.
var enableTelegramMessages = false; // Set to true to enable Telegram 
var telegramBotToken = ''; // Replace with your Telegram bot token
var telegramChatId = ''; // Replace with your Telegram chat ID
