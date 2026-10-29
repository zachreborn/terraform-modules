mock_provider "aws" {}

variables {
  name          = "ttl-fixture"
  protocol_type = "WEBSOCKET"
}

run "websocket_legacy_ttl" {
  command = plan
  variables {
    authorizers = {
      request = { authorizer_type = "REQUEST", authorizer_result_ttl = 300 }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["request"]]
}

run "websocket_legacy_zero" {
  command = plan
  variables {
    authorizers = {
      request = { authorizer_type = "REQUEST", authorizer_result_ttl = 0 }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["request"]]
}

run "websocket_canonical_ttl" {
  command = plan
  variables {
    authorizers = {
      request = { authorizer_type = "REQUEST", authorizer_result_ttl_in_seconds = 300 }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["request"]]
}

run "websocket_canonical_zero" {
  command = plan
  variables {
    authorizers = {
      request = { authorizer_type = "REQUEST", authorizer_result_ttl_in_seconds = 0 }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["request"]]
}

run "jwt_legacy_ttl" {
  command = plan
  variables {
    protocol_type = "HTTP"
    authorizers = {
      jwt = {
        authorizer_type       = "JWT"
        authorizer_result_ttl = 0
        jwt_configuration     = { audience = ["fixture"], issuer = "https://issuer.invalid" }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["jwt"]]
}

run "jwt_canonical_ttl" {
  command = plan
  variables {
    protocol_type = "HTTP"
    authorizers = {
      jwt = {
        authorizer_type                  = "JWT"
        authorizer_result_ttl_in_seconds = 300
        jwt_configuration                = { audience = ["fixture"], issuer = "https://issuer.invalid" }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["jwt"]]
}

run "websocket_without_ttl" {
  command = plan
  variables {
    authorizers = {
      request = { authorizer_type = "REQUEST" }
    }
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.this["request"].authorizer_type == "REQUEST"
    error_message = "WebSocket REQUEST authorizers remain supported without TTL."
  }
}
