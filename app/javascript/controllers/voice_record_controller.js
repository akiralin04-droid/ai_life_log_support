import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="voice-record"
export default class extends Controller {
  // HTML側と連携する要素を定義します
  static targets = [ "button", "status", "output" ]

  connect() {
    this.isRecording = false

    // ① ブラウザが音声入力(Web Speech API)に対応しているかチェック
    window.SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!window.SpeechRecognition) {
      this.statusTarget.classList.remove("d-none")
      this.statusTarget.textContent = "⚠️ お使いのブラウザは音声入力に非対応です。SafariやChromeをご利用ください。"
      this.statusTarget.classList.replace("text-primary", "text-danger")
      this.buttonTarget.disabled = true
      return
    }

    // ② 音声認識の設定
    this.recognition = new window.SpeechRecognition()
    this.recognition.lang = 'ja-JP'       // 日本語に設定
    this.recognition.interimResults = true // 途中経過も取得する
    this.recognition.continuous = true     // 喋り続けても録音を止めない

    // ③ 音声を認識した時の処理
    this.recognition.onresult = (event) => {
      let finalTranscript = ''
      for (let i = event.resultIndex; i < event.results.length; i++) {
        if (event.results[i].isFinal) {
          // 確定した文章だけを取り出す
          finalTranscript += event.results[i][0].transcript + ' '
        }
      }
      
      // ④ 確定したテキストを、生データ用のテキストエリアに追記する
      if (finalTranscript !== '') {
        const currentText = this.outputTarget.value
        this.outputTarget.value = currentText + finalTranscript
      }
    }

    // ⑤ エラーが起きた時の処理（フェイルセーフ対応）
    this.recognition.onerror = (event) => {
      console.error("音声認識エラー:", event.error)
      this.stopRecording()
      this.statusTarget.textContent = "⚠️ エラーが発生しました。もう一度お試しください。"
      this.statusTarget.classList.replace("text-primary", "text-danger")
    }
  }

  // ボタンが押された時の切り替え処理
  toggle() {
    if (this.isRecording) {
      this.stopRecording()
    } else {
      this.startRecording()
    }
  }

  startRecording() {
    this.isRecording = true
    this.recognition.start()
    
    // UIの見た目を「録音中（赤色）」に変更
    this.buttonTarget.classList.replace("btn-outline-danger", "btn-danger")
    this.statusTarget.classList.remove("d-none")
    this.statusTarget.textContent = "🎙️ 録音中...（もう一度押すと停止）"
    this.statusTarget.classList.replace("text-danger", "text-primary")
  }

  stopRecording() {
    this.isRecording = false
    this.recognition.stop()
    
    // UIの見た目を「停止中（白抜き）」に戻す
    this.buttonTarget.classList.replace("btn-danger", "btn-outline-danger")
    this.statusTarget.classList.add("d-none")
  }
}