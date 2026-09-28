package com.omnicart.dto.request;

import jakarta.validation.constraints.NotBlank;

public class EmbeddingRequest {
    @NotBlank(message = "Feature vector JSON is required (e.g. [0.12, -0.45, ...])")
    private String featureVector;

    private String modelVersion = "v1.0";

    public EmbeddingRequest() {}

    public String getFeatureVector() { return featureVector; }
    public void setFeatureVector(String featureVector) { this.featureVector = featureVector; }

    public String getModelVersion() { return modelVersion; }
    public void setModelVersion(String modelVersion) { this.modelVersion = modelVersion; }
}
