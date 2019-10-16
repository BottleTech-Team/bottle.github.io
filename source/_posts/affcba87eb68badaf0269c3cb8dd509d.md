------
title: web移动端支付
author: writer
date: undefined
tags: 
 - web
archives: 
 - web支付
categories: 
 - payment
------
**常见的移动端支付有：微信公众号内支付，第三方浏览器唤起微信app||支付宝app支付，微信小程序||支付宝小程序支付。**


由于微信公众号内只能使用微信JSAPI支付，以及一些其他的支付方式只能在特定的环境下进行，所以需要判断h5项目代码运行的环境选择对应的支付方式：

```
if (/MicroMessenger/.test(window.navigator.userAgent)) {
    // 微信内
} else if (/AlipayClient/.test(window.navigator.userAgent)) {
    // 支付宝内
} else {
  // 第三方浏览器
}
```


* * *


由于微信支付需要用到用户的openid，进行支付前需要获取用户的openid。用户在微信客户端中访问第三方网页，公众号可以通过微信网页授权机制，来获取用户基本信息，进而实现业务逻辑。
```
location.href = `https://open.weixin.qq.com/connect/oauth2/authorize?appid=${appid}&redirect_uri=${url}&response_type=code&scope=snsapi_base&state=drugstore#wechat_redirect`;
// appid	必填参数	公众号的唯一标识
// redirect_uri	必填参数	"授权后重定向的回调链接地址， 请使用 urlEncode 对链接进行处理"
// response_type	必填参数	返回类型，请填写code
// scope	必填参数	"应用授权作用域，snsapi_base （不弹出授权页面，直接跳转，只能获取用户openid），snsapi_userinfo （弹出授权页面，可通过openid拿到昵称、性别、所在地。并且， 即使在未关注的情况下，只要用户授权，也能获取其信息 ）"
// state	可选参数	重定向后会带上state参数，开发者可以填写a-zA-Z0-9的参数值，最多128字节
// #wechat_redirect	必填参数	无论直接打开还是做页面302重定向时候，必须带此参数
```

网页授权获取用户openid接口文档https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html
注意：开发者需要先到公众平台官网中的“开发 - 接口权限 - 网页服务 - 网页帐号 - 网页授权获取用户基本信息”的配置选项中，修改授权回调域名。请注意，这里填写的是域名（是一个字符串），而不是URL，因此请勿加 http:// 等协议头；



* * *


微信内H5调起支付：

```
function onBridgeReady(){
   WeixinJSBridge.invoke(
      'getBrandWCPayRequest', {
         "appId":"wx2421b1c4370ec43b",     //公众号名称，由商户传入     
         "timeStamp":"1395712654",         //时间戳，自1970年以来的秒数     
         "nonceStr":"e61463f8efa94090b1f366cccfbbb444", //随机串     
         "package":"prepay_id=u802345jgfjsdfgsdg888",     
         "signType":"MD5",         //微信签名方式：     
         "paySign":"70EA570631E4BB79628FBCA90534C63FF7FADD89" //微信签名 
      },
      function(res){
      if(res.err_msg == "get_brand_wcpay_request:ok" ){
      // 使用以上方式判断前端返回,微信团队郑重提示：
            //res.err_msg将在用户支付成功后返回ok，但并不保证它绝对可靠。
      } 
   }); 
}
if (typeof WeixinJSBridge == "undefined"){
   if( document.addEventListener ){
       document.addEventListener('WeixinJSBridgeReady', onBridgeReady, false);
   }else if (document.attachEvent){
       document.attachEvent('WeixinJSBridgeReady', onBridgeReady); 
       document.attachEvent('onWeixinJSBridgeReady', onBridgeReady);
   }
}else{
   onBridgeReady();
}
```

微信内H5调起支付官网文档链接：https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=7_7&index=6
补充：需要在微信商户平台（pay.weixin.qq.com）设置支付目录，以及设置授权域名。具体参考https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=7_3


* * *


第三方浏览器唤起微信app支付：

```
//1、用户在商户侧完成下单，使用微信支付进行支付
//2、由商户后台向微信支付发起下单请求（调用统一下单接口）注：交易类型trade_type=MWEB
//3、统一下单接口返回支付相关参数给商户后台，如支付跳转url（参数名“mweb_url”），商户通过mweb_url调起微信支付中间页
//4、中间页进行H5权限的校验，安全性检查（此处常见错误请见下文）
//5、如支付成功，商户后台会接收到微信侧的异步通知
//6、用户在微信支付收银台完成支付或取消支付,返回商户页面（默认为返回支付发起页面）
//7、商户在展示页面，引导用户主动发起支付结果的查询
//8,9、商户后台判断是否接到收微信侧的支付结果通知，如没有，后台调用我们的订单查询接口确认订单状态
//10、展示最终的订单支付结果给用户

// 一、回调页面
//正常流程用户支付完成后会返回至发起支付的页面，如需返回至指定页面，则可以在MWEB_URL后拼接上redirect_url参数，来指定回调页面。
location.href = mweb_url + '&redirect_url=' + encodeURIComponent('回调页面地址');
```

补充：一.需对redirect_url进行urlencode处理。  二.由于设置redirect_url后,回跳指定页面的操作可能发生在：1,微信支付中间页调起微信收银台后超过5秒 2,用户点击“取消支付“或支付完成后点“完成”按钮。因此无法保证页面回跳时，支付流程已结束，所以商户设置的redirect_url地址不能自动执行查单操作，应让用户去点击按钮触发查单操作。


* * *


第三方浏览器唤起支付宝app支付：

```
//端页面以Form表单的形式发起请求，浏览器会自动跳转至支付宝的相关页面（一般是收银台或签约页面），用户在该页面完成相关业务操作后再回跳到商户指定页面。
const form = res.data.data; // 返回的表单
const div = document.createElement('div');
div.id = 'alipay';
div.innerHTML = form;
document.body.appendChild(div);
document.querySelector('#alipay').children[0].submit(); // 执行后会唤起支付宝
```

支付宝h5支付官网文档链接：https://docs.open.alipay.com/203


* * *


微信小程序支付：

```
wx.requestPayment(
{
    'timeStamp': '', //时间戳从1970年1月1日00:00:00至今的秒数,即当前的时间
    'nonceStr': '', //随机字符串，长度为32个字符以下。
    'package': '', //统一下单接口返回的 prepay_id 参数值，提交格式如：prepay_id=*
    'signType': 'MD5', //签名类型，默认为MD5，支持HMAC-SHA256和MD5。注意此处需与统一下单的签名类型一致
    'paySign': '', //签名,具体签名方案参见微信公众号支付帮助文档:https://pay.weixin.qq.com/wiki/doc/api/wxa/wxa_api.php?chapter=4_3;
    'success':function(res){
        //接口调用成功的回调函数
       //requestPayment:ok 调用支付成功
       //requestPayment:fail cancel 用户取消支付
       //requestPayment:fail (detail message)调用支付失败，其中 detail message 为后台返回的详细失败原因
    },
    'fail':function(res){
        //接口调用失败的回调函数
    },
    'complete':function(res){
        //接口调用结束的回调函数（调用成功、失败都会执行）
    }
})
```

微信小程序调起支付API官网文档链接：https://pay.weixin.qq.com/wiki/doc/api/wxa/wxa_api.php?chapter=7_7&index=5
补充：程序访问商户服务都是通过HTTPS,开发部署的时候需要安装HTTPS服务器


* * *


支付宝小程序支付：

```
my.tradePay({
  // 调用统一收单交易创建接口（alipay.trade.create），获得返回字段支付宝交易号trade_no
  tradeNO: '201711152100110410533667792',
  success: (res) => {
       // res.resultCode === '9000'  订单处理成功。
  },
  fail: (res) => {
    
  }
});
// resultCode 结果码 
// 9000 订单处理成功。
// 8000 正在处理中。
// 4000 订单处理失败。
// 6001 用户中途取消。
// 6002 网络连接出错。
// 6004 处理结果未知（有可能已经成功），请查询商户订单列表中订单状态。
// 99 用户点击忘记密码导致快捷界面退出（only iOS）。
```

支付宝小程序调起支付API官网文档链接：https://docs.alipay.com/mini/api/openapi-pay
补充：小程序支付在小程序内不能通过扫码、条码、声波付等方式支付，只能唤起收银台进行支付；目前小程序支付还不支持免密支付。
