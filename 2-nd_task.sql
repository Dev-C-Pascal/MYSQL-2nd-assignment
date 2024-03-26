create database hiking;
use hiking;

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    profile VARCHAR(255) NOT NULL
);

CREATE TABLE locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    country VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,
    coordinates POINT NOT NULL
);

CREATE TABLE difficulty (
    difficulty_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE trails (
    trail_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    length DECIMAL(5,2) NOT NULL,
    elevation INT NOT NULL,
    description TEXT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    location_id INT NOT NULL,
    FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

CREATE TABLE trail_difficulty (
    trail_id INT NOT NULL,
    difficulty_id INT NOT NULL,
    PRIMARY KEY (trail_id, difficulty_id),
    FOREIGN KEY (trail_id) REFERENCES trails(trail_id),
    FOREIGN KEY (difficulty_id) REFERENCES difficulty(difficulty_id)
);

CREATE TABLE ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    trail_id INT NOT NULL,
    score INT CHECK (score >= 1 AND score <= 5),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (trail_id) REFERENCES trails(trail_id)
);

CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    trail_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    review_date DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (trail_id) REFERENCES trails(trail_id)
);


#

SELECT
    u.user_id,
    u.name,
    COUNT(re.review_id) AS total_reviews,
    AVG(ra.score) AS average_rating,
    CASE
        WHEN COUNT(re.review_id) > 20 THEN 'Highly Active'
        WHEN COUNT(re.review_id) BETWEEN 10 AND 20 THEN 'Moderately Active'
        ELSE 'Low Activity'
    END AS activity_level
FROM
    users u
LEFT JOIN
    reviews re ON u.user_id = re.user_id
LEFT JOIN
    ratings ra ON u.user_id = ra.user_id
GROUP BY
    u.user_id
ORDER BY
    total_reviews DESC, average_rating DESC;




SELECT
    t.name AS trail_name,
    AVG(r.score) AS average_rating
FROM
    trails t
JOIN
    ratings r ON t.trail_id = r.trail_id
GROUP BY
    t.trail_id, t.name
HAVING
    AVG(r.score) >= 4
ORDER BY
    average_rating DESC
LIMIT 10;





CREATE TABLE trails_clone LIKE trails;
INSERT INTO trails_clone SELECT * FROM trails;
CREATE INDEX idx_name ON trails_clone(name);

EXPLAIN SELECT * FROM trails WHERE name = 'qweqweqwe';
SELECT COUNT(1) FROM trails;
SELECT COUNT(1) FROM trails_clone;
EXPLAIN SELECT * FROM trails_clone WHERE name = 'qweqweqwe';


#assaignment 3

#= with non-correlated subqueries result
    #selct
SELECT t.name, t.length
FROM trails t
WHERE t.length > (SELECT AVG(length) FROM trails);


    #UPDATE
UPDATE difficulty d
SET d.description = 'Considered more challenging than previously rated.'
WHERE d.difficulty_id IN (
    SELECT td.difficulty_id
    FROM trail_difficulty td
    JOIN ratings r ON td.trail_id = r.trail_id
    GROUP BY td.difficulty_id
    HAVING AVG(r.score) < 3
);


#DELETE

DELETE FROM ratings
WHERE trail_id NOT IN (
    SELECT trail_id FROM trails
);

# IN with non-correlated subqueries result

SELECT *
FROM users
WHERE user_id IN (
    SELECT user_id
    FROM ratings
    WHERE score = 5
);

UPDATE users
SET profile = 'inactive'
WHERE user_id NOT IN (
    SELECT DISTINCT user_id
    FROM reviews
);

DELETE FROM trails
WHERE trail_id NOT IN (
    SELECT DISTINCT trail_id
    FROM ratings
);


#NOT IN with non-correlated subqueries result

SELECT u.name, u.email
FROM users u
WHERE u.user_id NOT IN (
    SELECT r.user_id
    FROM reviews r
);

UPDATE users u
SET u.profile = 'inactive'
WHERE u.user_id NOT IN (
    SELECT ra.user_id
    FROM ratings ra
);

DELETE FROM trails
WHERE trail_id NOT IN (
    SELECT ra.trail_id
    FROM ratings ra
)
AND trail_id NOT IN (
    SELECT re.trail_id
    FROM reviews re
);


#EXISTS with non-correlated subqueries result
SELECT t.trail_id, t.name
FROM trails t
WHERE EXISTS (
    SELECT 1
    FROM ratings r
    WHERE r.trail_id = t.trail_id
);


UPDATE trails t
SET description = CONCAT('Popular: ', description)
WHERE EXISTS (
    SELECT 1
    FROM ratings r
    WHERE r.trail_id = t.trail_id AND r.score = 5
);


DELETE FROM users
WHERE NOT EXISTS (
    SELECT 1
    FROM reviews r
    WHERE r.user_id = users.user_id
);


#NOT EXISTS with non-correlated subqueries result

SELECT u.name AS user_name
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM reviews r
    WHERE r.user_id = u.user_id
);

UPDATE ratings r
SET r.score = CASE
                WHEN r.score < 5 THEN r.score + 1
                ELSE 5
             END
WHERE NOT EXISTS (
    SELECT 1
    FROM reviews rv
    JOIN users u ON rv.user_id = u.user_id AND u.profile = 'pro'
    WHERE rv.trail_id = r.trail_id
);


DELETE FROM locations l
WHERE NOT EXISTS (
    SELECT 1
    FROM trails t
    WHERE t.location_id = l.location_id
);

#= with correlated subqueries result
SELECT t.name AS trail_name, AVG(r.score) AS average_rating
FROM trails t
JOIN ratings r ON t.trail_id = r.trail_id
GROUP BY t.name
HAVING AVG(r.score) > (SELECT AVG(r.score) FROM ratings r);


UPDATE users u
SET u.profile = 'pro'
WHERE (SELECT AVG(r.score) FROM ratings r WHERE r.user_id = u.user_id) >= 4.5;


DELETE FROM trails
WHERE trail_id NOT IN (SELECT DISTINCT trail_id FROM reviews);


#IN with correlated subqueries result
SELECT DISTINCT u.name
FROM users u
WHERE EXISTS (
    SELECT 1
    FROM ratings r
    JOIN trails t ON r.trail_id = t.trail_id
    JOIN trail_difficulty td ON t.trail_id = td.trail_id
    JOIN difficulty d ON td.difficulty_id = d.difficulty_id
    WHERE d.name = 'Hard'
    AND r.user_id = u.user_id
);



DELETE FROM ratings
WHERE trail_id IN (
    SELECT t.trail_id
    FROM trails t
    JOIN ratings r ON t.trail_id = r.trail_id
    GROUP BY t.trail_id
    HAVING SUM(CASE WHEN r.score < 3 THEN 1 ELSE 0 END) > COUNT(r.rating_id) * 0.5
);


#NOT IN with correlated subqueries result
SELECT u.user_id, u.name
FROM users u
WHERE u.user_id NOT IN (
    SELECT r.user_id
    FROM reviews r
    WHERE r.user_id = u.user_id
);

UPDATE users u
SET u.profile = 'inactive'
WHERE u.user_id NOT IN (
    SELECT ra.user_id
    FROM ratings ra
    WHERE ra.user_id = u.user_id
);

DELETE FROM trails
WHERE trail_id NOT IN (
    SELECT ra.trail_id
    FROM ratings ra
) AND trail_id NOT IN (
    SELECT re.trail_id
    FROM reviews re
);

#EXISTS with correlated subqueries result
SELECT t.name AS TrailName
FROM trails t
WHERE EXISTS (
    SELECT 1
    FROM ratings r
    WHERE r.trail_id = t.trail_id
    AND r.score = 5
);

UPDATE trails t
SET t.description = CONCAT(t.description, ' Warning: This trail is rated as Hard and may be challenging for some hikers.')
WHERE EXISTS (
    SELECT 1
    FROM trail_difficulty td
    JOIN difficulty d ON td.difficulty_id = d.difficulty_id
    WHERE td.trail_id = t.trail_id
    AND d.name = 'Hard'
);

DELETE FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM reviews r
    WHERE r.user_id = u.user_id
);


#NOT EXISTS with correlated subqueries result

SELECT u.name, u.email
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM reviews r
    WHERE r.user_id = u.user_id
);

UPDATE users u
SET u.profile = 'inactive'
WHERE NOT EXISTS (
    SELECT 1
    FROM ratings r
    WHERE r.user_id = u.user_id
);

DELETE FROM trails t
WHERE NOT EXISTS (
    SELECT 1
    FROM trail_difficulty td
    WHERE td.trail_id = t.trail_id
);


# UNION / UNION ALL / INTERSECT / EXCEPT

SELECT country AS place FROM locations
UNION
SELECT region FROM locations;

SELECT profile AS info FROM users
UNION ALL
SELECT name FROM trails;


SELECT DISTINCT t.name AS trail_name
FROM trails t
INNER JOIN ratings ra ON t.trail_id = ra.trail_id
INNER JOIN reviews re ON t.trail_id = re.trail_id AND ra.user_id = re.user_id;


SELECT t.name AS trail_name
FROM trails t
LEFT JOIN reviews r ON t.trail_id = r.trail_id
WHERE r.review_id IS NULL;



# drop database hiking;