package com.jackwallner.mahj

import com.jackwallner.mahj.data.InMemoryStore
import com.jackwallner.mahj.data.ReviewAccess
import java.security.MessageDigest
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReviewAccessTest {
    private fun digest(value: String) = MessageDigest.getInstance("SHA-256")
        .digest(value.toByteArray()).joinToString("") { "%02x".format(it) }

    @Test
    fun codeGrantsAccessAndSurvivesRestart() {
        val defaults = InMemoryStore()
        val hash = digest("review-test-code")
        val access = ReviewAccess(defaults, hash)
        assertFalse(access.isGranted)
        assertFalse(access.activate("wrong"))
        assertTrue(access.activate(" review-test-code "))
        assertTrue(ReviewAccess(defaults, hash).isGranted)
        assertFalse(ReviewAccess(defaults, digest("replacement")).isGranted)
    }

    @Test
    fun missingConfigurationNeverGrantsAccess() {
        val access = ReviewAccess(InMemoryStore(), "")
        assertFalse(access.activate(""))
        assertFalse(access.isGranted)
    }
}
