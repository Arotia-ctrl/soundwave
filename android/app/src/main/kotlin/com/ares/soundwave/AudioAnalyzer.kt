package com.ares.soundwave

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.exp
import kotlin.math.ln
import kotlin.math.log10
import kotlin.math.log2
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Décode un extrait du morceau (lecture seule, le fichier n'est jamais modifié)
 * puis calcule des mesures brutes. La décision Soft / Non-soft est prise côté Dart.
 */
object AudioAnalyzer {
    private const val TARGET_RATE = 11025
    private const val ANALYSIS_SECONDS = 45
    private const val MIN_SECONDS = 8
    private const val FRAME = 1024
    private const val HOP = 256

    private class Pcm(val samples: FloatArray, val sampleRate: Int)

    fun analyze(context: Context, uri: Uri): Map<String, Double>? {
        val pcm = decode(context, uri) ?: return null
        return extractFeatures(pcm.samples, pcm.sampleRate)
    }

    // ------------------------------------------------------------------
    // Décodage : extrait mono, sous-échantillonné autour de 11 kHz
    // ------------------------------------------------------------------
    private fun decode(context: Context, uri: Uri): Pcm? {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null
        try {
            extractor.setDataSource(context, uri, null)

            var format: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                val mime = f.getString(MediaFormat.KEY_MIME) ?: continue
                if (mime.startsWith("audio/")) {
                    extractor.selectTrack(i)
                    format = f
                    break
                }
            }
            if (format == null) return null
            val mime = format.getString(MediaFormat.KEY_MIME) ?: return null

            val durationUs =
                if (format.containsKey(MediaFormat.KEY_DURATION)) format.getLong(MediaFormat.KEY_DURATION) else 0L
            val windowUs = ANALYSIS_SECONDS * 1_000_000L
            if (durationUs > windowUs * 2) {
                extractor.seekTo(durationUs / 4, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
            }

            codec = MediaCodec.createDecoderByType(mime)
            codec.configure(format, null, null, 0)
            codec.start()

            var channels = max(1, format.getInteger(MediaFormat.KEY_CHANNEL_COUNT))
            var sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            var factor = max(1, sampleRate / TARGET_RATE)
            var outRate = sampleRate / factor

            val out = FloatArray(24_000 * ANALYSIS_SECONDS)
            var outCount = 0
            var acc = 0f
            var accN = 0

            val info = MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false
            val deadline = System.currentTimeMillis() + 60_000

            while (!outputDone &&
                outCount < min(out.size, outRate * ANALYSIS_SECONDS) &&
                System.currentTimeMillis() < deadline
            ) {
                if (!inputDone) {
                    val inIdx = codec.dequeueInputBuffer(10_000)
                    if (inIdx >= 0) {
                        val inBuf = codec.getInputBuffer(inIdx)!!
                        val size = extractor.readSampleData(inBuf, 0)
                        if (size < 0) {
                            codec.queueInputBuffer(inIdx, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            codec.queueInputBuffer(inIdx, 0, size, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }

                val outIdx = codec.dequeueOutputBuffer(info, 10_000)
                if (outIdx >= 0) {
                    val outBuf = codec.getOutputBuffer(outIdx)!!
                    outBuf.position(info.offset)
                    outBuf.limit(info.offset + info.size)
                    val shorts = outBuf.order(ByteOrder.nativeOrder()).asShortBuffer()
                    val frames = shorts.remaining() / channels
                    for (i in 0 until frames) {
                        var s = 0f
                        for (c in 0 until channels) s += shorts.get()
                        acc += s / (channels * 32768f)
                        accN++
                        if (accN == factor) {
                            if (outCount < out.size) out[outCount++] = acc / factor
                            acc = 0f
                            accN = 0
                        }
                    }
                    codec.releaseOutputBuffer(outIdx, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
                } else if (outIdx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    val nf = codec.outputFormat
                    channels = max(1, nf.getInteger(MediaFormat.KEY_CHANNEL_COUNT))
                    sampleRate = nf.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    factor = max(1, sampleRate / TARGET_RATE)
                    outRate = sampleRate / factor
                    acc = 0f
                    accN = 0
                }
            }

            if (outCount < outRate * MIN_SECONDS) return null
            return Pcm(out.copyOf(outCount), outRate)
        } finally {
            try { codec?.stop() } catch (_: Throwable) {}
            try { codec?.release() } catch (_: Throwable) {}
            extractor.release()
        }
    }

    // ------------------------------------------------------------------
    // Mesures : volume, dynamique, brillance, tempo
    // ------------------------------------------------------------------
    private fun extractFeatures(x: FloatArray, sr: Int): Map<String, Double>? {
        val frames = (x.size - FRAME) / HOP + 1
        if (frames < 100) return null

        val half = FRAME / 2
        val window = FloatArray(FRAME) { (0.5 - 0.5 * cos(2.0 * PI * it / (FRAME - 1))).toFloat() }
        val re = FloatArray(FRAME)
        val im = FloatArray(FRAME)
        val prevLog = FloatArray(half)
        val onset = DoubleArray(frames)
        val frameDb = DoubleArray(frames)

        var totalSq = 0.0
        var centroidSum = 0.0
        var centroidCount = 0

        for (f in 0 until frames) {
            val start = f * HOP
            var sq = 0.0
            for (i in 0 until FRAME) {
                val s = x[start + i]
                sq += (s * s).toDouble()
                re[i] = s * window[i]
                im[i] = 0f
            }
            totalSq += sq
            frameDb[f] = 20.0 * log10(max(sqrt(sq / FRAME), 1e-6))

            fft(re, im)

            var flux = 0.0
            var magSum = 0.0
            var weighted = 0.0
            for (k in 1 until half) {
                val mag = sqrt((re[k] * re[k] + im[k] * im[k]).toDouble())
                val lg = ln(1.0 + 100.0 * mag).toFloat()
                val d = lg - prevLog[k]
                if (d > 0f) flux += d.toDouble()
                prevLog[k] = lg
                magSum += mag
                weighted += mag * k
            }
            onset[f] = flux
            if (frameDb[f] > -50.0 && magSum > 0.0) {
                centroidSum += (weighted / magSum) * sr.toDouble() / FRAME
                centroidCount++
            }
        }
        onset[0] = 0.0

        // Volume moyen (dBFS)
        val meanSq = totalSq / (frames.toDouble() * FRAME)
        val loudnessDb = 10.0 * log10(max(meanSq, 1e-12))
        if (loudnessDb < -60.0) return null // quasi silence : inexploitable

        // Plage dynamique : écart entre les passages forts et faibles
        val valid = frameDb.filter { it > -60.0 }.sorted()
        val dynamicRange = if (valid.size >= 50) {
            valid[(0.95 * (valid.size - 1)).toInt()] - valid[(0.10 * (valid.size - 1)).toInt()]
        } else 0.0

        val centroid = if (centroidCount > 0) centroidSum / centroidCount else 0.0

        // Tempo : autocorrélation de l'enveloppe des attaques
        val fps = sr.toDouble() / HOP
        val smooth = max(3, (fps * 0.5).toInt())
        val env = DoubleArray(frames)
        for (i in 0 until frames) {
            val lo = max(0, i - smooth)
            val hi = min(frames - 1, i + smooth)
            var s = 0.0
            for (j in lo..hi) s += onset[j]
            env[i] = max(0.0, onset[i] - s / (hi - lo + 1))
        }

        var ac0 = 0.0
        for (v in env) ac0 += v * v
        ac0 /= frames

        var bpm = 0.0
        var strength = 0.0

        if (ac0 > 1e-9) {
            val lagMin = max(2, (fps * 60.0 / 200.0).toInt())
            val lagMax = min(frames / 2, (fps * 60.0 / 60.0).toInt() + 1)
            val ac = DoubleArray(lagMax + 2)
            for (lag in (lagMin - 1)..(lagMax + 1)) {
                var s = 0.0
                for (i in 0 until frames - lag) s += env[i] * env[i + lag]
                ac[lag] = s / (frames - lag)
            }

            var bestLag = -1
            var bestScore = -1.0
            for (lag in lagMin..lagMax) {
                if (!(ac[lag] > ac[lag - 1] && ac[lag] >= ac[lag + 1])) continue
                val candidate = 60.0 * fps / lag
                val x2 = log2(candidate / 110.0) / 0.9
                val score = ac[lag] * exp(-0.5 * x2 * x2) // préférence pour 70-160 BPM
                if (score > bestScore) {
                    bestScore = score
                    bestLag = lag
                }
            }

            if (bestLag > 0) {
                val y0 = ac[bestLag - 1]
                val y1 = ac[bestLag]
                val y2 = ac[bestLag + 1]
                val denom = y0 - 2 * y1 + y2
                val shift = if (denom != 0.0) (0.5 * (y0 - y2) / denom).coerceIn(-1.0, 1.0) else 0.0
                bpm = 60.0 * fps / (bestLag + shift)
                strength = (ac[bestLag] / ac0).coerceIn(0.0, 1.0)
            }
        }

        return hashMapOf(
            "bpm" to bpm,
            "rhythmStrength" to strength,
            "loudnessDb" to loudnessDb,
            "dynamicRangeDb" to dynamicRange,
            "centroidHz" to centroid,
        )
    }

    private fun fft(re: FloatArray, im: FloatArray) {
        val n = re.size
        var j = 0
        for (i in 1 until n) {
            var bit = n shr 1
            while ((j and bit) != 0) {
                j = j xor bit
                bit = bit shr 1
            }
            j = j xor bit
            if (i < j) {
                val tr = re[i]; re[i] = re[j]; re[j] = tr
                val ti = im[i]; im[i] = im[j]; im[j] = ti
            }
        }
        var len = 2
        while (len <= n) {
            val ang = -2.0 * PI / len
            val wlr = cos(ang).toFloat()
            val wli = sin(ang).toFloat()
            var i = 0
            while (i < n) {
                var wr = 1f
                var wi = 0f
                for (k in 0 until len / 2) {
                    val ur = re[i + k]
                    val ui = im[i + k]
                    val vr = re[i + k + len / 2] * wr - im[i + k + len / 2] * wi
                    val vi = re[i + k + len / 2] * wi + im[i + k + len / 2] * wr
                    re[i + k] = ur + vr
                    im[i + k] = ui + vi
                    re[i + k + len / 2] = ur - vr
                    im[i + k + len / 2] = ui - vi
                    val nwr = wr * wlr - wi * wli
                    wi = wr * wli + wi * wlr
                    wr = nwr
                }
                i += len
            }
            len = len shl 1
        }
    }
}