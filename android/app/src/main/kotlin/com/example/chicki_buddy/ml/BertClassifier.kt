package com.example.chicki_buddy.ml

import android.content.Context
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.common.FileUtil
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.io.FileNotFoundException
import android.util.Log

class BertClassifier(context: Context) {
    private val interpreter: Interpreter
    private val tokenizer: TokenizerHelper
    private val maxLength = 512

    init {
        val modelPath = "models/model.tflite"
        try {
          val model = FileUtil.loadMappedFile(context, modelPath)
          Log.i("BertClassifier", "✅ Model loaded successfully: $modelPath (${model.capacity()} bytes)")

          interpreter = Interpreter(model)
          tokenizer = TokenizerHelper(context)
        } catch (e: FileNotFoundException) {
            Log.e("BertClassifier", "❌ Model file not found: $modelPath")
            throw e
        } catch (e: Exception) {
            Log.e("BertClassifier", "❌ Failed to load model: ${e.message}")
            throw e
        }
    }

fun classify(text: String): Int {
    return try {
      // Thêm vào đầu hàm classify để debug
Log.i("BertClassifier", "maxLength variable = $maxLength")
for (i in 0 until interpreter.inputTensorCount) {
    val tensor = interpreter.getInputTensor(i)
    Log.i("BertClassifier", "Input $i: name=${tensor.name()}, shape=${tensor.shape().joinToString()}, bytes=${tensor.numBytes()}")
}
     // Tokenize input
val inputIds = tokenizer.tokenize(text, maxLength)
Log.i("BertClassifier", "Tokenized length=${inputIds.size}, first tokens=${inputIds.take(10)}")

// Attention mask (1 cho token thật, 0 cho padding)
val attentionMask = LongArray(maxLength) { i ->
    if (i < inputIds.size && inputIds[i] != 0) 1L else 0L
}

// Convert IntArray -> LongArray
val inputIdsLong = LongArray(maxLength) { i ->
    if (i < inputIds.size) inputIds[i].toLong() else 0L
}

// Helper: chuyển mảng Long -> ByteBuffer (INT64)
fun toLongBuffer(arr: LongArray): ByteBuffer {
    return ByteBuffer.allocateDirect(arr.size * 8).apply {
        order(ByteOrder.nativeOrder())
        arr.forEach { putLong(it) }
        rewind()
    }
}

// Chuẩn bị input tensor [1, maxLength]
val inputIdsBuffer = toLongBuffer(inputIdsLong)
val attentionMaskBuffer = toLongBuffer(attentionMask)

Log.i("BertClassifier", "First 50 ids=${inputIds.take(50)}")
Log.i("BertClassifier", "First 50 mask=${attentionMask.take(50)}")

val outputTensor = interpreter.getOutputTensor(0)
val outputShape = outputTensor.shape() // [1, 60]
Log.i("BertClassifier", "Output tensor shape=${outputShape.joinToString()}")

val numLabels = outputShape[1]
val outputBuffer = ByteBuffer.allocateDirect(numLabels * 4).apply {
    order(ByteOrder.nativeOrder())
}

// Run inference
val inputs = arrayOf(inputIdsBuffer, attentionMaskBuffer)
val outputs = mutableMapOf<Int, Any>()
outputs[0] = outputBuffer
try {
    interpreter.runForMultipleInputsOutputs(inputs, outputs)
} catch (e: Exception) {
    Log.e("BertClassifier", "classify failed", e)
    return -1
}

// Process results
outputBuffer.rewind()
val probabilities = FloatArray(numLabels) { outputBuffer.float }

Log.i("BertClassifier", "Output probabilities=${probabilities.joinToString()}")
Log.i("BertClassifier", "Attention mask non-zero=${attentionMask.count { it == 1L }}")

// Return argmax
return probabilities.indices.maxByOrNull { probabilities[it] } ?: -1
        
    } catch (e: Exception) {
        Log.e("BertClassifier", "❌ classify failed: ${e.message}", e)
        -1
    }
}

    fun close() {
        interpreter.close()
    }
}