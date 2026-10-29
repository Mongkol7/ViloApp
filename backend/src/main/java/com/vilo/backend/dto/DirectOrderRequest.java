package com.vilo.backend.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public class DirectOrderRequest {
    @NotEmpty
    @Valid
    private List<DirectOrderItemRequest> items;
    private String notes;

    public DirectOrderRequest() {}

    public List<DirectOrderItemRequest> getItems() { return items; }
    public void setItems(List<DirectOrderItemRequest> items) { this.items = items; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
}
