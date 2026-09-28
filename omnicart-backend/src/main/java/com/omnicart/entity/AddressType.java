package com.omnicart.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "AddressType")
public class AddressType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "AddressTypeID")
    private Integer id;

    @Column(name = "TypeName", nullable = false, unique = true, length = 50)
    private String typeName;

    public AddressType() {}

    public AddressType(Integer id, String typeName) {
        this.id = id;
        this.typeName = typeName;
    }

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getTypeName() { return typeName; }
    public void setTypeName(String typeName) { this.typeName = typeName; }
}
