package com.jgfactory.mooingtest.controller

import org.springframework.beans.factory.annotation.Value
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

@RestController
class HealthController(
    @Value("\${app.version:unknown}") private val version: String,
) {

    @GetMapping("/")
    fun health(): ResponseEntity<String> {
        return ResponseEntity.ok("OK")
    }

    // 배포 후 어떤 버전이 떠 있는지 확인용
    @GetMapping("/version")
    fun version(): ResponseEntity<String> {
        return ResponseEntity.ok(version)
    }
}
