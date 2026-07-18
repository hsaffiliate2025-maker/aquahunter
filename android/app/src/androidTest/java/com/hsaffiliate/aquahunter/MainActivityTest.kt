package com.hsaffiliate.aquahunter

import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test

class MainActivityTest {
    @get:Rule
    val composeRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun primaryNavigationOpensEveryMvpSurface() {
        val acceptanceGate = composeRule.onAllNodesWithTag("maritime-risk-accept").fetchSemanticsNodes()
        if (acceptanceGate.isNotEmpty()) {
            composeRule.onNodeWithTag("maritime-risk-confirmation").performClick()
            composeRule.onNodeWithTag("maritime-risk-accept").performClick()
            composeRule.waitForIdle()
        }

        composeRule.onNodeWithText("Global seafood pulse").assertIsDisplayed()

        composeRule.onNodeWithText("Markets").performClick()
        composeRule.onNodeWithText("Global markets").assertIsDisplayed()

        composeRule.onNodeWithText("Radar").performClick()
        composeRule.onNodeWithText("Probability, not detection.").assertIsDisplayed()

        composeRule.onNodeWithText("Network").performClick()
        composeRule.onNodeWithText("Verified routes to market.").assertIsDisplayed()
        composeRule.onNodeWithText("Vessels").performClick()
        composeRule.onNodeWithText("Vessel signals unavailable").assertIsDisplayed()

        composeRule.onNodeWithText("Pulse").performClick()
        composeRule.onNodeWithContentDescription("Settings").performClick()
        composeRule.onNodeWithText("Settings").assertIsDisplayed()
    }
}
