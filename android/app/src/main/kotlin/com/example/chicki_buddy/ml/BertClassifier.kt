package com.example.chicki_buddy.ml

import android.content.Context
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.common.FileUtil
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.io.FileNotFoundException
import android.util.Log
import kotlin.math.*

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
            
            // Debug input/output info
            logModelInfo()
        } catch (e: FileNotFoundException) {
            Log.e("BertClassifier", "❌ Model file not found: $modelPath")
            throw e
        } catch (e: Exception) {
            Log.e("BertClassifier", "❌ Failed to load model: ${e.message}")
            throw e
        }
    }

    private fun logModelInfo() {
        Log.i("BertClassifier", "=== MODEL INFO ===")
        for (i in 0 until interpreter.inputTensorCount) {
            val tensor = interpreter.getInputTensor(i)
            Log.i("BertClassifier", "Input $i: name='${tensor.name()}', shape=${tensor.shape().joinToString()}, dtype=${tensor.dataType()}")
        }
        for (i in 0 until interpreter.outputTensorCount) {
            val tensor = interpreter.getOutputTensor(i)
            Log.i("BertClassifier", "Output $i: name='${tensor.name()}', shape=${tensor.shape().joinToString()}, dtype=${tensor.dataType()}")
        }
    }

    fun classify(text: String): Int {
        return try {
            // Tokenize input
            val inputIds = tokenizer.tokenize(text, maxLength)
            Log.i("BertClassifier", "Input text: $text")
            Log.i("BertClassifier", "Tokenized length=${inputIds.size}, first 30 tokens=${inputIds.take(30)}")

            // Tạo attention mask
            val attentionMask = LongArray(maxLength) { i ->
                if (i < inputIds.size && inputIds[i] != 0) 1L else 0L
            }

            // Convert to LongArray với proper shape [1, maxLength]
            val inputIdsLong = LongArray(maxLength) { i ->
                if (i < inputIds.size) inputIds[i].toLong() else 0L
            }

            // Tạo ByteBuffer với shape [1, maxLength]
            val inputIdsBuffer = createLongBuffer(inputIdsLong)
            val attentionMaskBuffer = createLongBuffer(attentionMask)

            Log.i("BertClassifier", "First 30 input_ids: ${inputIdsLong.take(30)}")
            Log.i("BertClassifier", "First 30 attention_mask: ${attentionMask.take(30)}")

            // Prepare inputs - QUAN TRỌNG: đúng thứ tự theo tên tensor
            val inputs = mutableMapOf<Int, Any>()
            
            // Tìm đúng index cho input_ids và attention_mask
            for (i in 0 until interpreter.inputTensorCount) {
                val tensor = interpreter.getInputTensor(i)
                val tensorName = tensor.name() ?: ""
                
                when {
                    tensorName.contains("input_ids", ignoreCase = true) -> {
                        inputs[i] = inputIdsBuffer
                        Log.i("BertClassifier", "Set input_ids at index $i")
                    }
                    tensorName.contains("attention_mask", ignoreCase = true) -> {
                        inputs[i] = attentionMaskBuffer  
                        Log.i("BertClassifier", "Set attention_mask at index $i")
                    }
                    else -> {
                        Log.w("BertClassifier", "Unknown input tensor: $tensorName at index $i")
                    }
                }
            }

            // Prepare output
            val outputTensor = interpreter.getOutputTensor(0)
            val outputShape = outputTensor.shape() // [1, num_labels]
            Log.i("BertClassifier", "Output tensor shape: ${outputShape.joinToString()}")
            
            val batchSize = outputShape[0]
            val numLabels = outputShape[1]
            val outputBuffer = ByteBuffer.allocateDirect(batchSize * numLabels * 4).apply {
                order(ByteOrder.nativeOrder())
            }

            val outputs = mutableMapOf<Int, Any>()
            outputs[0] = outputBuffer

            // Run inference
            interpreter.allocateTensors() // Đảm bảo tensors được allocate
            interpreter.runForMultipleInputsOutputs(inputs.values.toTypedArray(), outputs)
            interpreter.close() // Giải phóng tài nguyên ngay sau khi dùng xong

            // Process output - đây là raw logits, cần softmax như Python
            outputBuffer.rewind()
            val rawLogits = FloatArray(numLabels) { outputBuffer.float }
            
            Log.i("BertClassifier", "Raw logits: ${rawLogits.joinToString()}")
            
            // Apply softmax to get probabilities (như Python)
            val probabilities = applySoftmax(rawLogits)
            Log.i("BertClassifier", "Probabilities after softmax: ${probabilities.joinToString()}")

            // Return argmax
            val prediction = probabilities.indices.maxByOrNull { probabilities[it] } ?: -1
            Log.i("BertClassifier", "Predicted class: $prediction (confidence: ${probabilities[prediction]})")
            
            return prediction

        } catch (e: Exception) {
            Log.e("BertClassifier", "❌ classify failed: ${e.message}", e)
            -1
        }
    }

    private fun createLongBuffer(array: LongArray): ByteBuffer {
        return ByteBuffer.allocateDirect(array.size * 8).apply {
            order(ByteOrder.nativeOrder())
            array.forEach { putLong(it) }
            rewind()
        }
    }

    private fun applySoftmax(logits: FloatArray): FloatArray {
        // Subtract max for numerical stability
        val maxLogit = logits.maxOrNull() ?: 0f
        val expLogits = logits.map { exp(it - maxLogit) }
        val sumExp = expLogits.sum()
        return expLogits.map { (it / sumExp).toFloat() }.toFloatArray()
    }

    fun close() {
        interpreter.close()
    }
}