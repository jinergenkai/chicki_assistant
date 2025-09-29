package com.example.chicki_buddy

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import com.example.chicki_buddy.ml.BertClassifier

class IntentClassifierPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var classifier: BertClassifier

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "intent_classifier")
        channel.setMethodCallHandler(this)
        classifier = BertClassifier(context)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        classifier.close()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "classify" -> {
                val text = call.argument<String>("text")
                if (text == null) {
                    result.error("INVALID_ARGUMENT", "Text is null", null)
                    return
                }
                try {
                  val intentId = classifier.classify(text)
                  result.success(intentId)
                }
                catch (e: Exception) {
                  result.error("CLASSIFICATION_ERROR", "Error during classification: ${e.message}", null)
                }
            }
            else -> result.notImplemented()
        }
    }
}