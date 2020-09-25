package com.braze.brazeplugin

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

import com.appboy.Appboy
import com.appboy.AppboyLifecycleCallbackListener
import com.appboy.configuration.CachedConfigurationProvider
import com.appboy.enums.Gender
import com.appboy.enums.Month
import com.appboy.enums.NotificationSubscriptionType
import com.appboy.models.cards.Card
import com.appboy.models.IInAppMessage
import com.appboy.models.IInAppMessageImmersive
import com.appboy.models.MessageButton
import com.appboy.models.outgoing.AppboyProperties
import com.appboy.models.outgoing.AttributionData
import com.appboy.services.AppboyLocationService
import com.appboy.ui.activities.AppboyContentCardsActivity

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log

import java.math.BigDecimal
import java.io.IOException

class BrazePlugin: MethodCallHandler {
  var context : Context
  var registrar : Registrar
  val channel : MethodChannel

  companion object {
    lateinit var pluginInstance : BrazePlugin
    var pluginInitialized = false
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "braze_plugin")
      pluginInstance = BrazePlugin(registrar.context(), registrar, channel)
      channel.setMethodCallHandler(pluginInstance)
      pluginInitialized = true
    }

    @JvmStatic
    fun processInAppMessage(inAppMessage: IInAppMessage) {
      if (pluginInitialized) {
        val inAppMessageMap: HashMap<String, String> =
          hashMapOf("inAppMessage" to inAppMessage.forJsonPut().toString())
        if (pluginInstance.registrar.activity() != null) {
          pluginInstance.registrar.activity().runOnUiThread(Runnable {
            pluginInstance.channel.invokeMethod("handleBrazeInAppMessage", inAppMessageMap)
          })
        }
      }
    }

    @JvmStatic
    fun processContentCards(contentCardList: ArrayList<Card>) {
      if (pluginInitialized) {
        if (pluginInstance.registrar.activity() != null) {
          pluginInstance.registrar.activity().runOnUiThread(Runnable {
            val cardStringList = arrayListOf<String>()
            for (card in contentCardList) {
              cardStringList.add(card.forJsonPut().toString())
            }
            val contentCardMap: HashMap<String, ArrayList<String>> = hashMapOf("contentCards" to cardStringList)
            pluginInstance.channel.invokeMethod("handleBrazeContentCards", contentCardMap)
          })
        }
      }
    }
  }

  constructor(context : Context, registrar : Registrar, channel : MethodChannel) {
    this.context = context
    this.registrar = registrar
    this.channel = channel
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    com.appboy.support.AppboyLogger.setLogLevel(2)
    try {
      when (call.method) {
        "changeUser" -> {
          val userId = call.argument<String>("userId")
          Appboy.getInstance(context).changeUser(userId)
        }
        "requestContentCardsRefresh" -> {
          Appboy.getInstance(context).requestContentCardsRefresh(false)
        }
        "launchContentCards" -> {
          if (pluginInstance.registrar.activity() != null) {
            val intent=Intent(this.registrar.activity(), AppboyContentCardsActivity::class.java)
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            this.context.startActivity(intent)
          }
        }
        "logContentCardClicked" -> {
          val contentCardString = call.argument<String>("contentCardString")
          if (contentCardString != null) {
            val contentCard = Appboy.getInstance(context).deserializeContentCard(contentCardString)
            if (contentCard != null) {
              contentCard.logClick()
            }
          }
        }
        "logContentCardImpression" -> {
          val contentCardString = call.argument<String>("contentCardString")
          if (contentCardString != null) {
            val contentCard = Appboy.getInstance(context).deserializeContentCard(contentCardString)
            if (contentCard != null) {
              contentCard.logImpression()
            }
          }
        }
        "logContentCardDismissed" -> {
          val contentCardString = call.argument<String>("contentCardString")
          if (contentCardString != null) {
            val contentCard = Appboy.getInstance(context).deserializeContentCard(contentCardString)
            if (contentCard != null) {
              contentCard.setIsDismissed(true)
            }
          }
        }
        "logInAppMessageClicked" -> {
          val inAppMessage = Appboy.getInstance(context)
              .deserializeInAppMessageString(call.argument<String>("inAppMessageString"))
          if (inAppMessage != null) {
            inAppMessage.logClick()
          }
        }
        "logInAppMessageImpression" -> {
          val inAppMessage = Appboy.getInstance(context)
              .deserializeInAppMessageString(call.argument<String>("inAppMessageString"))
          if (inAppMessage != null) {
            inAppMessage.logImpression()
          }
        }
        "logInAppMessageButtonClicked" -> {
          val inAppMessage = Appboy.getInstance(context)
              .deserializeInAppMessageString(call.argument<String>("inAppMessageString"))
          if (inAppMessage is IInAppMessageImmersive) {
            val buttonId = call.argument<Int>("buttonId")?: 0
            val inAppMessageImmersive = inAppMessage as IInAppMessageImmersive
            for (button in inAppMessageImmersive.getMessageButtons().orEmpty()) {
              if (button.getId() === buttonId) {
                inAppMessageImmersive.logButtonClick(button)
                break
              }
            }
          }
        }
        "getInstallTrackingId" -> {
          result.success(Appboy.getInstance(context).getInstallTrackingId())
        }
        "addAlias" -> {
          val aliasName = call.argument<String>("aliasName")
          val aliasLabel = call.argument<String>("aliasLabel")
          Appboy.getInstance(context).getCurrentUser()?.addAlias(aliasName, aliasLabel)
        }
        "logCustomEvent" -> {
          val eventName = call.argument<String>("eventName")
          val properties = convertToAppboyProperties(
                  call.argument<Map<String, *>>("properties"))
          Appboy.getInstance(context).logCustomEvent(eventName, properties)
        }
        "logPurchase" -> {
          val productId = call.argument<String>("productId")
          val currencyCode = call.argument<String>("currencyCode")
          val price = call.argument<Double>("price")?: 0.0
          val quantity = call.argument<Int>("quantity")?: 1
          val properties = convertToAppboyProperties(
                  call.argument<Map<String, *>>("properties"))
          Appboy.getInstance(context).logPurchase(productId, currencyCode, BigDecimal(price),
                  quantity, properties)
        }
        "addToCustomAttributeArray" -> {
          val key = call.argument<String>("key")
          val value = call.argument<String>("value")
          Appboy.getInstance(context).getCurrentUser()?.addToCustomAttributeArray(key, value)
        }
        "removeFromCustomAttributeArray" -> {
          val key = call.argument<String>("key")
          val value = call.argument<String>("value")
          Appboy.getInstance(context).getCurrentUser()?.removeFromCustomAttributeArray(key, value)
        }
        "setStringCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          val value = call.argument<String>("value")
          Appboy.getInstance(context).getCurrentUser()?.setCustomUserAttribute(key, value)
        }
        "setDoubleCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          val value = call.argument<Double>("value")?: 0.0
          Appboy.getInstance(context).getCurrentUser()?.setCustomUserAttribute(key, value)
        }
        "setDateCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          val value = (call.argument<Int>("value")?: 0).toLong()
          Appboy.getInstance(context).getCurrentUser()?.setCustomUserAttributeToSecondsFromEpoch(
                  key, value)
        }
        "setIntCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          val value = call.argument<Int>("value")?: 0
          Appboy.getInstance(context).getCurrentUser()?.setCustomUserAttribute(key, value)
        }
        "incrementCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          val value = call.argument<Int>("value")?: 0
          Appboy.getInstance(context).getCurrentUser()?.incrementCustomUserAttribute(key, value)
        }
        "setPushNotificationSubscriptionType" -> {
          val type = getSubscriptionType(call.argument<String>("type")?: "")
          Appboy.getInstance(context).getCurrentUser()?.setPushNotificationSubscriptionType(type)
        }
        "setEmailNotificationSubscriptionType" -> {
          val type = getSubscriptionType(call.argument<String>("type")?: "")
          Appboy.getInstance(context).getCurrentUser()?.setEmailNotificationSubscriptionType(type)
        }
        "setBoolCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          val value = call.argument<Boolean>("value")?: false
          Appboy.getInstance(context).getCurrentUser()?.setCustomUserAttribute(key, value)
        }
        "setLocationCustomAttribute" -> {
          val key = call.argument<String>("key")
          val lat = call.argument<Double>("lat")?: 0.0
          val long = call.argument<Double>("long")?: 0.0
          Appboy.getInstance(context).getCurrentUser()?.setLocationCustomAttribute(key, lat, long)
        }
        "requestImmediateDataFlush" -> {
          Appboy.getInstance(context).requestImmediateDataFlush()
        }
        "unsetCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          Appboy.getInstance(context).getCurrentUser()?.unsetCustomUserAttribute(key)
        }
        "setFirstName" -> {
          val firstName = call.argument<String>("firstName")
          Appboy.getInstance(context).getCurrentUser()?.setFirstName(firstName)
        }
        "setLastName" -> {
          val lastName = call.argument<String>("lastName")
          Appboy.getInstance(context).getCurrentUser()?.setLastName(lastName)
        }
        "setDateOfBirth" -> {
          val year = call.argument<Int>("year")?: 0
          val month = getMonth(call.argument<Int>("month")?: 0)
          val day = call.argument<Int>("day")?: 0
          Appboy.getInstance(context).getCurrentUser()?.setDateOfBirth(year, month, day)
        }
        "setEmail" -> {
          val email = call.argument<String>("email")
          Appboy.getInstance(context).getCurrentUser()?.setEmail(email)
        }
        "setGender" -> {
          val gender = call.argument<String>("gender")
          val genderUpper = gender?.toUpperCase()?: ""
          val genderEnum: Gender
          if (genderUpper.startsWith("F")) {
            genderEnum = Gender.FEMALE
          } else if (genderUpper.startsWith("M")) {
            genderEnum = Gender.MALE
          } else if (genderUpper.startsWith("N")) {
            genderEnum = Gender.NOT_APPLICABLE
          } else if (genderUpper.startsWith("O")) {
            genderEnum = Gender.OTHER
          } else if (genderUpper.startsWith("P")) {
            genderEnum = Gender.PREFER_NOT_TO_SAY
          } else if (genderUpper.startsWith("U")) {
            genderEnum = Gender.UNKNOWN
          } else {
            return
          }
          Appboy.getInstance(context).getCurrentUser()?.setGender(genderEnum)
        }
        "setLanguage" -> {
          val language = call.argument<String>("language")
          Appboy.getInstance(context).getCurrentUser()?.setLanguage(language)
        }
        "setCountry" -> {
          val country = call.argument<String>("country")
          Appboy.getInstance(context).getCurrentUser()?.setCountry(country)
        }
        "setHomeCity" -> {
          val homeCity = call.argument<String>("homeCity")
          Appboy.getInstance(context).getCurrentUser()?.setHomeCity(homeCity)
        }
        "setPhoneNumber" -> {
          val phoneNumber = call.argument<String>("phoneNumber")
          Appboy.getInstance(context).getCurrentUser()?.setPhoneNumber(phoneNumber)
        }
        "setAttributionData" -> {
          val network = call.argument<String>("network")
          val campaign = call.argument<String>("campaign")
          val adGroup = call.argument<String>("adGroup")
          val creative = call.argument<String>("creative")
          val attributionData = AttributionData(network, campaign, adGroup, creative)
          Appboy.getInstance(context).getCurrentUser()?.setAttributionData(attributionData)
        }
        "setAvatarImageUrl" -> {
          val avatarImageUrl = call.argument<String>("avatarImageUrl")
          Appboy.getInstance(context).getCurrentUser()?.setAvatarImageUrl(avatarImageUrl)
        }
        "registerAndroidPushToken" -> {
          val pushToken = call.argument<String>("pushToken")
          Appboy.getInstance(context).registerAppboyPushMessages(pushToken)
        }
        "wipeData" -> {
          Appboy.wipeData(context)
        }
        "requestLocationInitialization" -> {
          AppboyLocationService.requestInitialization(context);
        }
        "enableSDK" -> {
          Appboy.enableSdk(context)
        }
        "disableSDK" -> {
          Appboy.disableSdk(context)
        }
        else -> result.notImplemented()
      }
    } catch (e: IOException) {
      result.error("IOException encountered", call.method, e)
    }
  }

  private fun getSubscriptionType(type: String): NotificationSubscriptionType? {
    return when (type.trim()) {
      "SubscriptionType.subscribed" -> NotificationSubscriptionType.SUBSCRIBED
      "SubscriptionType.opted_in" -> NotificationSubscriptionType.OPTED_IN
      "SubscriptionType.unsubscribed" -> NotificationSubscriptionType.UNSUBSCRIBED
      else -> null
    }
  }

  private fun getMonth(month: Int): Month? {
    return when (month) {
      1 -> Month.JANUARY
      2 -> Month.FEBRUARY
      3 -> Month.MARCH
      4 -> Month.APRIL
      5 -> Month.MAY
      6 -> Month.JUNE
      7 -> Month.JULY
      8 -> Month.AUGUST
      9 -> Month.SEPTEMBER
      10 -> Month.OCTOBER
      11 -> Month.NOVEMBER
      12 -> Month.DECEMBER
      else -> null
    }
  }

  private fun convertToAppboyProperties(arguments: Map<String, *>?): AppboyProperties {
    val properties = AppboyProperties()
    if (arguments == null) {
      return properties
    }
    for (key in arguments.keys) {
      val value = arguments[key]
      if (value is Int) {
        properties.addProperty(key, value)
      } else if (value is String) {
        properties.addProperty(key, value)
      } else if (value is Double) {
        properties.addProperty(key, value)
      } else if (value is Boolean) {
        properties.addProperty(key, value)
      } else if (value is Long) {
        properties.addProperty(key, value.toInt())
      }
    }
    return properties
  }
}
