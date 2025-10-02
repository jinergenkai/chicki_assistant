[User upload / scan file]
          ↓
[OCR offline (ML Kit Android)]
          ↓
[Tokenize → split thành từ, normalize]
          ↓
[Filter → remove punctuation, stopwords, non-English]
          ↓
[Map với local vocabulary DB]
          ↓
[Create / update Vocabulary objects]
          ↓
[User interacts: search / quiz / flashcard / TTS offline]