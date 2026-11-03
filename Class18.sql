use sakila;

#Write a function that returns the amount of copies of a film in a store in sakila-db. 
#Pass either the film id or the film name and the store id.
DELIMITER $$
CREATE FUNCTION film_copies(
    pelicula VARCHAR(255),
    tienda INT
)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE cantidad INT;
    SELECT COUNT(*)
    INTO cantidad
    FROM inventory i
    JOIN film f ON i.film_id = f.film_id
    WHERE i.store_id = tienda
      AND (
          CAST(f.film_id AS CHAR) = pelicula
          OR f.title = pelicula
      );

    RETURN cantidad;
END $$
DELIMITER ;
#Write a stored procedure with an output parameter that contains a list of customer first and last names separated by ";", that live in a certain country. You pass the country it gives you the list of people living there. USE A CURSOR, do not use any aggregation function (ike CONTCAT_WS.

DELIMITER $$
CREATE PROCEDURE clientes_pais(
    IN pais VARCHAR(50),
    OUT lista TEXT
)
BEGIN
    DECLARE nombre VARCHAR(45);
    DECLARE apellido VARCHAR(45);
    DECLARE terminado BOOLEAN DEFAULT FALSE;
    DECLARE cursor_clientes CURSOR FOR
        SELECT c.first_name, c.last_name
        FROM customer c
        JOIN address a ON c.address_id = a.address_id
        JOIN city ci ON a.city_id = ci.city_id
        JOIN country co ON ci.country_id = co.country_id
        WHERE co.country = pais;
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET terminado = TRUE;
    SET lista = '';
    OPEN cursor_clientes;
    bucle: LOOP
        FETCH cursor_clientes INTO nombre, apellido;
        IF terminado THEN
            LEAVE bucle;
        END IF;
        IF lista = '' THEN
            SET lista = CONCAT(nombre, ' ', apellido);
        ELSE
            SET lista = CONCAT(lista, '; ', nombre, ' ', apellido);
        END IF;
    END LOOP;
    CLOSE cursor_clientes;
END $$
DELIMITER ;

#Review the function inventory_in_stock and the procedure film_in_stock explain the code, write usage examples.
DELIMITER $$

CREATE FUNCTION inventory_in_stock(id_inventario INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE alquileres INT;
    DECLARE pendientes INT;

    SELECT COUNT(*) INTO alquileres
    FROM rental
    WHERE inventory_id = id_inventario;

    IF alquileres = 0 THEN
        RETURN TRUE;
    END IF;

    SELECT COUNT(rental_id) INTO pendientes
    FROM inventory
    LEFT JOIN rental USING(inventory_id)
    WHERE inventory.inventory_id = id_inventario
      AND rental.return_date IS NULL;

    IF pendientes > 0 THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END $$

CREATE PROCEDURE film_in_stock(
    IN pelicula INT,
    IN tienda INT,
    OUT cantidad INT
)
READS SQL DATA
BEGIN
    SELECT inventory_id
    FROM inventory
    WHERE film_id = pelicula
      AND store_id = tienda
      AND inventory_in_stock(inventory_id);

    SELECT FOUND_ROWS() INTO cantidad;
END $$

DELIMITER ;