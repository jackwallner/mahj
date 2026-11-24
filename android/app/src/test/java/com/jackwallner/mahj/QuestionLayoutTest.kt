package com.jackwallner.mahj

import com.jackwallner.mahj.ui.components.missedOnTallQuestion
import com.jackwallner.mahj.ui.components.needsCompactQuestion
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Question layout on short screens: compact metrics when the regular ones would scroll, a rack recap on a tall miss. */
class QuestionLayoutTest {
    @Test
    fun onlyATallMissedRackQuestionRepeatsTheRack() {
        assertTrue(missedOnTallQuestion(missed = true, tileCount = 13, questionHeight = 1200, viewportHeight = 1600))
        assertFalse("A short question keeps its rack in view", missedOnTallQuestion(true, 13, 600, 1600))
        assertFalse("A right answer needs no recap", missedOnTallQuestion(false, 13, 1200, 1600))
        assertFalse("No rack, nothing to repeat", missedOnTallQuestion(true, 0, 1200, 1600))
        assertFalse("Not measured yet", missedOnTallQuestion(true, 13, 1200, 0))
    }

    @Test
    fun aQuestionGoesCompactOnlyWhenTheRegularOneWouldScroll() {
        assertTrue(needsCompactQuestion(questionHeight = 1300, viewportHeight = 1310, paddingPx = 52f))
        assertFalse(needsCompactQuestion(questionHeight = 1000, viewportHeight = 1310, paddingPx = 52f))
    }
}
