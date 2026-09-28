package com.omnicart.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "ShippingStatus")
public class ShippingStatus {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "StatusID")
    private Integer id;

    @Column(name = "StatusName", nullable = false, unique = true, length = 50)
    private String statusName;

    public ShippingStatus() {}

    public ShippingStatus(Integer id, String statusName) {
        this.id = id;
        this.statusName = statusName;
    }

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getStatusName() { return statusName; }
    public void setStatusName(String statusName) { this.statusName = statusName; }
}
