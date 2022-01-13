package com.hunter.chat_prototype

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.hunter.chat_prototype.Notification
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.hunter.check"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                    call, result -> if (call.method == "notif") {
                var title = call.argument<String>("title")
                var message = call.argument<String>("message")
                var channel = call.argument<String>("channel")
//
                Notification().create(context,title.toString(),message.toString(), channel.toString())
                println(title)
                println(message)
                println(channel)
                result.success("sendded")

            } else {
                result.notImplemented()
            }
        }
    }
}
