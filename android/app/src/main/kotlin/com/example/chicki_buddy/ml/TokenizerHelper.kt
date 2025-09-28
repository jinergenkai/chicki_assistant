package com.example.chicki_buddy.ml

import android.content.Context
import java.io.BufferedReader
import java.io.InputStreamReader
import android.util.Log

class TokenizerHelper(context: Context) {
    private val vocab: Map<String, Int>
    
    init {
        vocab = context.assets.open("models/vocab.txt").use { inputStream ->
            BufferedReader(InputStreamReader(inputStream)).useLines { lines ->
                lines.mapIndexed { index, token -> token to index }.toMap()
            }
        }
        Log.i("BertClassifier", "✅ Loaded vocab with ${vocab.size} tokens")
    }

    fun tokenize(text: String, maxLength: Int = 128): IntArray {
        val tokens = mutableListOf(vocab["[CLS]"]!!)
        
        text.lowercase().split(" ").forEach { word ->
            if (tokens.size >= maxLength - 1) return@forEach
            vocab[word]?.let { tokens.add(it) }
        }

        tokens.add(vocab["[SEP]"]!!)
        
        // Padding
        while (tokens.size < maxLength) {
            tokens.add(vocab["[PAD]"]!!)
        }

        Log.i("BertClassifier", "✅ 10 sample tokens: ${tokens.take(10)}")
        return tokens.toIntArray()
    }
}